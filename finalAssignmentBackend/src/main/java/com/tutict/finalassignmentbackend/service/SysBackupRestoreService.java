package com.tutict.finalassignmentbackend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.SysBackupRestore;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.SysBackupRestoreDocument;
import com.tutict.finalassignmentbackend.mapper.SysBackupRestoreMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.SysBackupRestoreSearchRepository;
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
public class SysBackupRestoreService {

    private static final Logger log = Logger.getLogger(SysBackupRestoreService.class.getName());
    private static final String CACHE_NAME = "sysBackupRestoreCache";

    private final SysBackupRestoreMapper sysBackupRestoreMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysBackupRestoreSearchRepository sysBackupRestoreSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysBackupRestoreService(SysBackupRestoreMapper sysBackupRestoreMapper,
                                   SysRequestHistoryMapper sysRequestHistoryMapper,
                                   SysBackupRestoreSearchRepository sysBackupRestoreSearchRepository,
                                   KafkaTemplate<String, String> kafkaTemplate,
                                   ObjectMapper objectMapper) {
        this.sysBackupRestoreMapper = sysBackupRestoreMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysBackupRestoreSearchRepository = sysBackupRestoreSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysBackupRestoreService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysBackupRestore backupRestore, String action) {
        Objects.requireNonNull(backupRestore, "SysBackupRestore must not be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            log.warning(() -> String.format("Duplicate sys backup/restore request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate sys backup/restore request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("sys_backup_restore_" + action, idempotencyKey, backupRestore);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(backupRestore.getBackupId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysBackupRestore createSysBackupRestore(SysBackupRestore backupRestore) {
        validateBackupRestore(backupRestore);
        sysBackupRestoreMapper.insert(backupRestore);
        syncToIndexAfterCommit(backupRestore);
        return backupRestore;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysBackupRestore updateSysBackupRestore(SysBackupRestore backupRestore) {
        validateBackupRestore(backupRestore);
        requirePositive(backupRestore.getBackupId());
        int rows = sysBackupRestoreMapper.updateById(backupRestore);
        if (rows == 0) {
            throw new IllegalStateException("SysBackupRestore not found for id=" + backupRestore.getBackupId());
        }
        syncToIndexAfterCommit(backupRestore);
        return backupRestore;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteSysBackupRestore(Long backupId) {
        requirePositive(backupId);
        int rows = sysBackupRestoreMapper.deleteById(backupId);
        if (rows == 0) {
            throw new IllegalStateException("SysBackupRestore not found for id=" + backupId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysBackupRestoreSearchRepository.deleteById(backupId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#backupId", unless = "#result == null")
    public SysBackupRestore findById(Long backupId) {
        requirePositive(backupId);
        return sysBackupRestoreSearchRepository.findById(backupId)
                .map(SysBackupRestoreDocument::toEntity)
                .orElseGet(() -> {
                    SysBackupRestore entity = sysBackupRestoreMapper.selectById(backupId);
                    if (entity != null) {
                        sysBackupRestoreSearchRepository.save(SysBackupRestoreDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<SysBackupRestore> findAll() {
        List<SysBackupRestore> fromIndex = StreamSupport.stream(sysBackupRestoreSearchRepository.findAll().spliterator(), false)
                .map(SysBackupRestoreDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<SysBackupRestore> fromDb = sysBackupRestoreMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long backupId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(backupId);
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

    private void sendKafkaMessage(String topic, String idempotencyKey, SysBackupRestore backupRestore) {
        try {
            String payload = objectMapper.writeValueAsString(backupRestore);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send SysBackupRestore Kafka message", ex);
            throw new RuntimeException("Failed to send sys backup/restore event", ex);
        }
    }

    private void syncToIndexAfterCommit(SysBackupRestore backupRestore) {
        if (backupRestore == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysBackupRestoreDocument doc = SysBackupRestoreDocument.fromEntity(backupRestore);
                if (doc != null) {
                    sysBackupRestoreSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysBackupRestore> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysBackupRestoreDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysBackupRestoreDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysBackupRestoreSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private void validateBackupRestore(SysBackupRestore backupRestore) {
        if (backupRestore == null) {
            throw new IllegalArgumentException("SysBackupRestore must not be null");
        }
        if (backupRestore.getBackupTime() == null) {
            backupRestore.setBackupTime(LocalDateTime.now());
        }
        if (isBlank(backupRestore.getStatus())) {
            backupRestore.setStatus("Pending");
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Backup ID" + " must be greater than zero");
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
