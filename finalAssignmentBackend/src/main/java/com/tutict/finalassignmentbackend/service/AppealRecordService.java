package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import com.tutict.finalassignmentbackend.mapper.AppealRecordMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.AppealRecordSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class AppealRecordService {

    private static final Logger log = Logger.getLogger(AppealRecordService.class.getName());
    private static final String CACHE = "appealRecordCache";

    private final AppealRecordMapper appealRecordMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final KafkaTemplate<String, AppealRecord> kafkaTemplate;
    private final AppealRecordSearchRepository appealRecordSearchRepository;

    @Autowired
    public AppealRecordService(AppealRecordMapper appealRecordMapper,
                               SysRequestHistoryMapper sysRequestHistoryMapper,
                               KafkaTemplate<String, AppealRecord> kafkaTemplate,
                               AppealRecordSearchRepository appealRecordSearchRepository) {
        this.appealRecordMapper = appealRecordMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.appealRecordSearchRepository = appealRecordSearchRepository;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    @WsAction(service = "AppealRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        Objects.requireNonNull(appealRecord, "Appeal record cannot be null");
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate appeal request detected");
        }

        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        sendKafkaMessage("appeal_" + action, appealRecord);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(Optional.ofNullable(appealRecord.getAppealId()).map(Long::valueOf).orElse(null));
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        validateAppeal(appealRecord);
        appealRecordMapper.insert(appealRecord);
        syncIndexAfterCommit(appealRecord);
        return appealRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        validateAppealId(appealRecord);
        int rows = appealRecordMapper.updateById(appealRecord);
        if (rows == 0) {
            throw new IllegalStateException("Appeal not found: " + appealRecord.getAppealId());
        }
        syncIndexAfterCommit(appealRecord);
        return appealRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public void deleteAppeal(Long appealId) {
        validateAppealId(appealId);
        int rows = appealRecordMapper.deleteById(appealId);
        if (rows == 0) {
            throw new IllegalStateException("Appeal not found: " + appealId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                appealRecordSearchRepository.deleteById(appealId);
            }
        });
    }

    @Cacheable(cacheNames = CACHE, key = "#appealId", unless = "#result == null")
    public AppealRecord getAppealById(Long appealId) {
        validateAppealId(appealId);
        return appealRecordSearchRepository.findById(appealId)
                .map(AppealRecordDocument::toEntity)
                .orElseGet(() -> {
                    AppealRecord entity = appealRecordMapper.selectById(appealId);
                    if (entity != null) {
                        appealRecordSearchRepository.save(AppealRecordDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Cacheable(cacheNames = CACHE, key = "'offense:' + #offenseId", unless = "#result.isEmpty()")
    public List<AppealRecord> findByOffenseId(Long offenseId, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
        SearchHits<AppealRecordDocument> hits = appealRecordSearchRepository.findByOffenseId(offenseId, pageable);
        if (hits != null && hits.hasSearchHits()) {
            return hits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(AppealRecordDocument::toEntity)
                    .collect(Collectors.toList());
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_id", offenseId);
        List<AppealRecord> db = appealRecordMapper.selectList(wrapper);
        db.stream()
                .map(AppealRecordDocument::fromEntity)
                .filter(Objects::nonNull)
                .forEach(appealRecordSearchRepository::save);
        return db;
    }

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

    private void sendKafkaMessage(String topic, AppealRecord appealRecord) {
        try {
            kafkaTemplate.send(topic, appealRecord);
        } catch (Exception e) {
            log.log(Level.WARNING, "Failed to send appeal Kafka message", e);
        }
    }

    private void syncIndexAfterCommit(AppealRecord appealRecord) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                AppealRecordDocument doc = AppealRecordDocument.fromEntity(appealRecord);
                if (doc != null) {
                    appealRecordSearchRepository.save(doc);
                }
            }
        });
    }

    private void validateAppeal(AppealRecord appealRecord) {
        if (appealRecord == null) {
            throw new IllegalArgumentException("Appeal record cannot be null");
        }
        if (appealRecord.getOffenseId() == null) {
            throw new IllegalArgumentException("Offense ID is required");
        }
    }

    private void validateAppealId(AppealRecord appealRecord) {
        validateAppeal(appealRecord);
        validateAppealId(appealRecord.getAppealId());
    }

    private void validateAppealId(Long appealId) {
        if (appealId == null || appealId <= 0) {
            throw new IllegalArgumentException("Invalid appeal ID: " + appealId);
        }
    }
}
