package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.SysPermission;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.SysPermissionDocument;
import com.tutict.finalassignmentbackend.mapper.SysPermissionMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.SysPermissionSearchRepository;
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
public class SysPermissionService {

    private static final Logger log = Logger.getLogger(SysPermissionService.class.getName());
    private static final String CACHE_NAME = "sysPermissionCache";

    private final SysPermissionMapper sysPermissionMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysPermissionSearchRepository sysPermissionSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysPermissionService(SysPermissionMapper sysPermissionMapper,
                                SysRequestHistoryMapper sysRequestHistoryMapper,
                                SysPermissionSearchRepository sysPermissionSearchRepository,
                                KafkaTemplate<String, String> kafkaTemplate,
                                ObjectMapper objectMapper) {
        this.sysPermissionMapper = sysPermissionMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysPermissionSearchRepository = sysPermissionSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysPermissionService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysPermission permission, String action) {
        Objects.requireNonNull(permission, "SysPermission must not be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            log.warning(() -> String.format("Duplicate sys permission request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate sys permission request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("sys_permission_" + action, idempotencyKey, permission);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(Optional.ofNullable(permission.getPermissionId()).map(Integer::longValue).orElse(null));
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysPermission createSysPermission(SysPermission permission) {
        validatePermission(permission);
        sysPermissionMapper.insert(permission);
        syncToIndexAfterCommit(permission);
        return permission;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysPermission updateSysPermission(SysPermission permission) {
        validatePermission(permission);
        requirePositive(permission.getPermissionId(), "Permission ID");
        int rows = sysPermissionMapper.updateById(permission);
        if (rows == 0) {
            throw new IllegalStateException("SysPermission not found for id=" + permission.getPermissionId());
        }
        syncToIndexAfterCommit(permission);
        return permission;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteSysPermission(Integer permissionId) {
        requirePositive(permissionId, "Permission ID");
        int rows = sysPermissionMapper.deleteById(permissionId);
        if (rows == 0) {
            throw new IllegalStateException("SysPermission not found for id=" + permissionId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysPermissionSearchRepository.deleteById(permissionId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#permissionId", unless = "#result == null")
    public SysPermission findById(Integer permissionId) {
        requirePositive(permissionId, "Permission ID");
        return sysPermissionSearchRepository.findById(permissionId)
                .map(SysPermissionDocument::toEntity)
                .orElseGet(() -> {
                    SysPermission entity = sysPermissionMapper.selectById(permissionId);
                    if (entity != null) {
                        sysPermissionSearchRepository.save(SysPermissionDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<SysPermission> findAll() {
        List<SysPermission> fromIndex = StreamSupport.stream(sysPermissionSearchRepository.findAll().spliterator(), false)
                .map(SysPermissionDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<SysPermission> fromDb = sysPermissionMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'parent:' + #parentId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysPermission> findByParentId(Integer parentId, int page, int size) {
        requireNonNegative(parentId, "Parent ID");
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.eq("parent_id", parentId)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Integer permissionId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(permissionId != null ? permissionId.longValue() : null);
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

    private void sendKafkaMessage(String topic, String idempotencyKey, SysPermission permission) {
        try {
            String payload = objectMapper.writeValueAsString(permission);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send SysPermission Kafka message", ex);
            throw new RuntimeException("Failed to send sys permission event", ex);
        }
    }

    private void syncToIndexAfterCommit(SysPermission permission) {
        if (permission == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysPermissionDocument doc = SysPermissionDocument.fromEntity(permission);
                if (doc != null) {
                    sysPermissionSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysPermission> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysPermissionDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysPermissionDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysPermissionSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private List<SysPermission> fetchFromDatabase(QueryWrapper<SysPermission> wrapper, int page, int size) {
        Page<SysPermission> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysPermissionMapper.selectPage(mpPage, wrapper);
        List<SysPermission> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private void validatePermission(SysPermission permission) {
        if (permission == null) {
            throw new IllegalArgumentException("SysPermission must not be null");
        }
        if (permission.getPermissionCode() == null || permission.getPermissionCode().isBlank()) {
            throw new IllegalArgumentException("Permission code must not be blank");
        }
        if (permission.getPermissionName() == null || permission.getPermissionName().isBlank()) {
            throw new IllegalArgumentException("Permission name must not be blank");
        }
        if (permission.getCreatedAt() == null) {
            permission.setCreatedAt(LocalDateTime.now());
        }
        if (permission.getUpdatedAt() == null) {
            permission.setUpdatedAt(LocalDateTime.now());
        }
        if (permission.getStatus() == null || permission.getStatus().isBlank()) {
            permission.setStatus("Active");
        }
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void requirePositive(Number number, String fieldName) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException(fieldName + " must be greater than zero");
        }
    }

    private void requireNonNegative(Number number, String fieldName) {
        if (number != null && number.intValue() < 0) {
            throw new IllegalArgumentException(fieldName + " must be >= 0");
        }
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
