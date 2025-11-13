package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.SysRequestHistoryDocument;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.SysRequestHistorySearchRepository;
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
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class SysRequestHistoryService {

    private static final Logger log = Logger.getLogger(SysRequestHistoryService.class.getName());
    private static final String CACHE_NAME = "sysRequestHistoryCache";

    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysRequestHistorySearchRepository sysRequestHistorySearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysRequestHistoryService(SysRequestHistoryMapper sysRequestHistoryMapper,
                                    SysRequestHistorySearchRepository sysRequestHistorySearchRepository,
                                    KafkaTemplate<String, String> kafkaTemplate,
                                    ObjectMapper objectMapper) {
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysRequestHistorySearchRepository = sysRequestHistorySearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysRequestHistoryService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysRequestHistory historyPayload, String action) {
        Objects.requireNonNull(historyPayload, "SysRequestHistory must not be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            log.warning(() -> String.format("Duplicate sys request history request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate sys request history request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("sys_request_history_" + action, idempotencyKey, historyPayload);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(historyPayload.getId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysRequestHistory createSysRequestHistory(SysRequestHistory history) {
        validateHistory(history);
        sysRequestHistoryMapper.insert(history);
        syncToIndexAfterCommit(history);
        return history;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysRequestHistory updateSysRequestHistory(SysRequestHistory history) {
        validateHistory(history);
        requirePositive(history.getId());
        int rows = sysRequestHistoryMapper.updateById(history);
        if (rows == 0) {
            throw new IllegalStateException("SysRequestHistory not found for id=" + history.getId());
        }
        syncToIndexAfterCommit(history);
        return history;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteSysRequestHistory(Long id) {
        requirePositive(id);
        int rows = sysRequestHistoryMapper.deleteById(id);
        if (rows == 0) {
            throw new IllegalStateException("SysRequestHistory not found for id=" + id);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysRequestHistorySearchRepository.deleteById(id);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#id", unless = "#result == null")
    public SysRequestHistory findById(Long id) {
        requirePositive(id);
        return sysRequestHistorySearchRepository.findById(id)
                .map(SysRequestHistoryDocument::toEntity)
                .orElseGet(() -> {
                    SysRequestHistory entity = sysRequestHistoryMapper.selectById(id);
                    if (entity != null) {
                        sysRequestHistorySearchRepository.save(SysRequestHistoryDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> findAll() {
        List<SysRequestHistory> fromIndex = StreamSupport.stream(sysRequestHistorySearchRepository.findAll().spliterator(), false)
                .map(SysRequestHistoryDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<SysRequestHistory> fromDb = sysRequestHistoryMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #status + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> findByBusinessStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("business_status", status)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    public Optional<SysRequestHistory> findByIdempotencyKey(String key) {
        if (isBlank(key)) {
            return Optional.empty();
        }
        return Optional.ofNullable(sysRequestHistoryMapper.selectByIdempotencyKey(key));
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long historyId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(historyId);
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

    private void sendKafkaMessage(String topic, String idempotencyKey, SysRequestHistory history) {
        try {
            String payload = objectMapper.writeValueAsString(history);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send SysRequestHistory Kafka message", ex);
            throw new RuntimeException("Failed to send sys request history event", ex);
        }
    }

    private void syncToIndexAfterCommit(SysRequestHistory history) {
        if (history == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysRequestHistoryDocument doc = SysRequestHistoryDocument.fromEntity(history);
                if (doc != null) {
                    sysRequestHistorySearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysRequestHistory> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysRequestHistoryDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysRequestHistoryDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysRequestHistorySearchRepository.saveAll(documents);
                }
            }
        });
    }

    private List<SysRequestHistory> fetchFromDatabase(QueryWrapper<SysRequestHistory> wrapper, int page, int size) {
        Page<SysRequestHistory> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRequestHistoryMapper.selectPage(mpPage, wrapper);
        List<SysRequestHistory> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private void validateHistory(SysRequestHistory history) {
        if (history == null) {
            throw new IllegalArgumentException("SysRequestHistory must not be null");
        }
        if (isBlank(history.getIdempotencyKey())) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        if (history.getCreatedAt() == null) {
            history.setCreatedAt(LocalDateTime.now());
        }
        if (history.getUpdatedAt() == null) {
            history.setUpdatedAt(LocalDateTime.now());
        }
        if (isBlank(history.getBusinessStatus())) {
            history.setBusinessStatus("PENDING");
        }
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("History ID" + " must be greater than zero");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
