package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.SysRolePermission;
import com.tutict.finalassignmentbackend.entity.elastic.SysRolePermissionDocument;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.SysRolePermissionMapper;
import com.tutict.finalassignmentbackend.repository.SysRolePermissionSearchRepository;
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

@Service
public class SysRolePermissionService {

    private static final Logger log = Logger.getLogger(SysRolePermissionService.class.getName());
    private static final String CACHE_NAME = "sysRolePermissionCache";

    private final SysRolePermissionMapper sysRolePermissionMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysRolePermissionSearchRepository sysRolePermissionSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysRolePermissionService(SysRolePermissionMapper sysRolePermissionMapper,
                                    SysRequestHistoryMapper sysRequestHistoryMapper,
                                    SysRolePermissionSearchRepository sysRolePermissionSearchRepository,
                                    KafkaTemplate<String, String> kafkaTemplate,
                                    ObjectMapper objectMapper) {
        this.sysRolePermissionMapper = sysRolePermissionMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysRolePermissionSearchRepository = sysRolePermissionSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysRolePermissionService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysRolePermission relation, String action) {
        Objects.requireNonNull(relation, "SysRolePermission must not be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            log.warning(() -> String.format("Duplicate role-permission request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate role-permission request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("sys_role_permission_" + action, idempotencyKey, relation);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(relation.getId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysRolePermission createRelation(SysRolePermission relation) {
        validateRelation(relation);
        sysRolePermissionMapper.insert(relation);
        syncToIndexAfterCommit(relation);
        return relation;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysRolePermission updateRelation(SysRolePermission relation) {
        validateRelation(relation);
        requirePositive(relation.getId(), "Relation ID");
        int rows = sysRolePermissionMapper.updateById(relation);
        if (rows == 0) {
            throw new IllegalStateException("SysRolePermission not found for id=" + relation.getId());
        }
        syncToIndexAfterCommit(relation);
        return relation;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteRelation(Long id) {
        requirePositive(id, "Relation ID");
        int rows = sysRolePermissionMapper.deleteById(id);
        if (rows == 0) {
            throw new IllegalStateException("SysRolePermission not found for id=" + id);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysRolePermissionSearchRepository.deleteById(id);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#id", unless = "#result == null")
    public SysRolePermission findById(Long id) {
        requirePositive(id, "Relation ID");
        return sysRolePermissionSearchRepository.findById(id)
                .map(SysRolePermissionDocument::toEntity)
                .orElseGet(() -> {
                    SysRolePermission entity = sysRolePermissionMapper.selectById(id);
                    if (entity != null) {
                        sysRolePermissionSearchRepository.save(SysRolePermissionDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'role:' + #roleId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRolePermission> findByRoleId(Integer roleId, int page, int size) {
        requirePositive(roleId, "Role ID");
        validatePagination(page, size);
        QueryWrapper<SysRolePermission> wrapper = new QueryWrapper<>();
        wrapper.eq("role_id", roleId);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'permission:' + #permissionId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRolePermission> findByPermissionId(Integer permissionId, int page, int size) {
        requirePositive(permissionId, "Permission ID");
        validatePagination(page, size);
        QueryWrapper<SysRolePermission> wrapper = new QueryWrapper<>();
        wrapper.eq("permission_id", permissionId);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all:' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRolePermission> findAll(int page, int size) {
        validatePagination(page, size);
        Page<SysRolePermission> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRolePermissionMapper.selectPage(mpPage, new QueryWrapper<>());
        List<SysRolePermission> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long relationId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(relationId);
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

    private void sendKafkaMessage(String topic, String idempotencyKey, SysRolePermission relation) {
        try {
            String payload = objectMapper.writeValueAsString(relation);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send SysRolePermission Kafka message", ex);
            throw new RuntimeException("Failed to send sys role permission event", ex);
        }
    }

    private void syncToIndexAfterCommit(SysRolePermission relation) {
        if (relation == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysRolePermissionDocument doc = SysRolePermissionDocument.fromEntity(relation);
                if (doc != null) {
                    sysRolePermissionSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysRolePermission> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysRolePermissionDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysRolePermissionDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysRolePermissionSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private List<SysRolePermission> fetchFromDatabase(QueryWrapper<SysRolePermission> wrapper, int page, int size) {
        Page<SysRolePermission> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRolePermissionMapper.selectPage(mpPage, wrapper);
        List<SysRolePermission> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private void validateRelation(SysRolePermission relation) {
        if (relation == null) {
            throw new IllegalArgumentException("SysRolePermission must not be null");
        }
        requirePositive(relation.getRoleId(), "Role ID");
        requirePositive(relation.getPermissionId(), "Permission ID");
        if (relation.getCreatedAt() == null) {
            relation.setCreatedAt(LocalDateTime.now());
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
