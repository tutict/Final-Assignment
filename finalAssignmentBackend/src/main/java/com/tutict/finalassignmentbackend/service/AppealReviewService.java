package com.tutict.finalassignmentbackend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.AppealReview;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.AppealReviewDocument;
import com.tutict.finalassignmentbackend.mapper.AppealReviewMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.AppealReviewSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class AppealReviewService {

    private static final Logger log = Logger.getLogger(AppealReviewService.class.getName());
    private static final String CACHE_NAME = "appealReviewCache";

    private final AppealReviewMapper appealReviewMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final AppealReviewSearchRepository appealReviewSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public AppealReviewService(AppealReviewMapper appealReviewMapper,
                               SysRequestHistoryMapper sysRequestHistoryMapper,
                               AppealReviewSearchRepository appealReviewSearchRepository,
                               KafkaTemplate<String, String> kafkaTemplate,
                               ObjectMapper objectMapper) {
        this.appealReviewMapper = appealReviewMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.appealReviewSearchRepository = appealReviewSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "AppealReviewService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealReview appealReview, String action) {
        Objects.requireNonNull(appealReview, "AppealReview must not be null");
        if (sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey) != null) {
            throw new RuntimeException("Duplicate appeal review request detected");
        }
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("appeal_review_" + action, idempotencyKey, appealReview);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(appealReview.getReviewId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public AppealReview createReview(AppealReview appealReview) {
        validateAppealReview(appealReview);
        appealReviewMapper.insert(appealReview);
        syncToIndexAfterCommit(appealReview);
        return appealReview;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public AppealReview updateReview(AppealReview appealReview) {
        validateAppealReview(appealReview);
        requirePositive(appealReview.getReviewId());
        int rows = appealReviewMapper.updateById(appealReview);
        if (rows == 0) {
            throw new IllegalStateException("No AppealReview updated for id=" + appealReview.getReviewId());
        }
        syncToIndexAfterCommit(appealReview);
        return appealReview;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteReview(Long reviewId) {
        requirePositive(reviewId);
        int rows = appealReviewMapper.deleteById(reviewId);
        if (rows == 0) {
            throw new IllegalStateException("No AppealReview deleted for id=" + reviewId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                appealReviewSearchRepository.deleteById(reviewId);
            }
        });
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "#reviewId", unless = "#result == null")
    public AppealReview findById(Long reviewId) {
        requirePositive(reviewId);
        return appealReviewSearchRepository.findById(reviewId)
                .map(AppealReviewDocument::toEntity)
                .orElseGet(() -> {
                    AppealReview entity = appealReviewMapper.selectById(reviewId);
                    if (entity != null) {
                        appealReviewSearchRepository.save(AppealReviewDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<AppealReview> findAll() {
        List<AppealReview> fromIndex = StreamSupport.stream(appealReviewSearchRepository.findAll().spliterator(), false)
                .map(AppealReviewDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<AppealReview> fromDb = appealReviewMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    public long countByReviewLevel(String reviewLevel) {
        return appealReviewSearchRepository.findByReviewLevel(reviewLevel, org.springframework.data.domain.PageRequest.of(0, 1))
                .getTotalHits();
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long reviewId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(reviewId);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, AppealReview appealReview) {
        try {
            String payload = objectMapper.writeValueAsString(appealReview);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send AppealReview Kafka message", ex);
            throw new RuntimeException("Failed to send AppealReview event", ex);
        }
    }

    private void syncToIndexAfterCommit(AppealReview appealReview) {
        if (appealReview == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                AppealReviewDocument doc = AppealReviewDocument.fromEntity(appealReview);
                if (doc != null) {
                    appealReviewSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<AppealReview> reviews) {
        if (reviews == null || reviews.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<AppealReviewDocument> documents = reviews.stream()
                        .filter(Objects::nonNull)
                        .map(AppealReviewDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    appealReviewSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private void validateAppealReview(AppealReview appealReview) {
        Objects.requireNonNull(appealReview, "AppealReview must not be null");
        if (appealReview.getReviewLevel() == null || appealReview.getReviewLevel().isBlank()) {
            throw new IllegalArgumentException("Review level must not be blank");
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Review ID" + " must be greater than zero");
        }
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
