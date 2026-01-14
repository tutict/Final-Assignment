package com.tutict.finalassignmentcloud.user.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.entity.SysUserRole;
import com.tutict.finalassignmentcloud.entity.elastic.SysUserRoleDocument;
import com.tutict.finalassignmentcloud.user.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.user.mapper.SysUserRoleMapper;
import com.tutict.finalassignmentcloud.user.repository.SysUserRoleSearchRepository;
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
public class SysUserRoleService {

    private static final Logger LOG = Logger.getLogger(SysUserRoleService.class.getName());
    private static final String CACHE_NAME = "sysUserRoleCache";

    private final SysUserRoleMapper sysUserRoleMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysUserRoleSearchRepository sysUserRoleSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysUserRoleService(SysUserRoleMapper sysUserRoleMapper,
                              SysRequestHistoryMapper sysRequestHistoryMapper,
                              SysUserRoleSearchRepository sysUserRoleSearchRepository,
                              KafkaTemplate<String, String> kafkaTemplate,
                              ObjectMapper objectMapper) {
        this.sysUserRoleMapper = sysUserRoleMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysUserRoleSearchRepository = sysUserRoleSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysUserRoleService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysUserRole relation, String action) {
        Objects.requireNonNull(relation, "SysUserRole must not be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            LOG.warning(() -> String.format("Duplicate sys user role request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate sys user role request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("sys_user_role_" + action, idempotencyKey, relation);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(relation.getId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysUserRole createRelation(SysUserRole relation) {
        validateRelation(relation);
        sysUserRoleMapper.insert(relation);
        syncToIndexAfterCommit(relation);
        return relation;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysUserRole updateRelation(SysUserRole relation) {
        validateRelation(relation);
        requirePositive(relation.getId(), "Relation ID");
        int rows = sysUserRoleMapper.updateById(relation);
        if (rows == 0) {
            throw new IllegalStateException("SysUserRole not found for id=" + relation.getId());
        }
        syncToIndexAfterCommit(relation);
        return relation;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteRelation(Long relationId) {
        requirePositive(relationId, "Relation ID");
        int rows = sysUserRoleMapper.deleteById(relationId);
        if (rows == 0) {
            throw new IllegalStateException("SysUserRole not found for id=" + relationId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysUserRoleSearchRepository.deleteById(relationId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#relationId", unless = "#result == null")
    public SysUserRole findById(Long relationId) {
        requirePositive(relationId, "Relation ID");
        return sysUserRoleSearchRepository.findById(relationId)
                .map(SysUserRoleDocument::toEntity)
                .orElseGet(() -> {
                    SysUserRole entity = sysUserRoleMapper.selectById(relationId);
                    if (entity != null) {
                        sysUserRoleSearchRepository.save(SysUserRoleDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'user:' + #userId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysUserRole> findByUserId(Long userId, int page, int size) {
        requirePositive(userId, "User ID");
        validatePagination(page, size);
        List<SysUserRole> index = mapHits(sysUserRoleSearchRepository.findByUserId(userId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysUserRole> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
                .orderByDesc("created_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'role:' + #roleId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysUserRole> findByRoleId(Integer roleId, int page, int size) {
        requirePositive(roleId, "Role ID");
        validatePagination(page, size);
        List<SysUserRole> index = mapHits(sysUserRoleSearchRepository.findByRoleId(roleId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysUserRole> wrapper = new QueryWrapper<>();
        wrapper.eq("role_id", roleId)
                .orderByDesc("created_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'userRole:' + #userId + ':' + #roleId + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysUserRole> findByUserIdAndRoleId(Long userId, Integer roleId, int page, int size) {
        requirePositive(userId, "User ID");
        requirePositive(roleId, "Role ID");
        validatePagination(page, size);
        List<SysUserRole> index = mapHits(sysUserRoleSearchRepository.findByUserIdAndRoleId(userId, roleId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysUserRole> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
                .eq("role_id", roleId)
                .orderByDesc("created_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all:' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysUserRole> findAll(int page, int size) {
        validatePagination(page, size);
        Page<SysUserRole> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysUserRoleMapper.selectPage(mpPage, new QueryWrapper<>());
        List<SysUserRole> records = mpPage.getRecords();
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
            LOG.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
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
            LOG.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, SysUserRole relation) {
        try {
            String payload = objectMapper.writeValueAsString(relation);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Failed to send SysUserRole Kafka message", ex);
            throw new RuntimeException("Failed to send SysUserRole event", ex);
        }
    }

    private void syncToIndexAfterCommit(SysUserRole relation) {
        if (relation == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysUserRoleDocument doc = SysUserRoleDocument.fromEntity(relation);
                if (doc != null) {
                    sysUserRoleSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysUserRole> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysUserRoleDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysUserRoleDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysUserRoleSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private List<SysUserRole> fetchFromDatabase(QueryWrapper<SysUserRole> wrapper, int page, int size) {
        Page<SysUserRole> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysUserRoleMapper.selectPage(mpPage, wrapper);
        List<SysUserRole> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private List<SysUserRole> mapHits(org.springframework.data.elasticsearch.core.SearchHits<SysUserRoleDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(SysUserRoleDocument::toEntity)
                .collect(Collectors.toList());
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validateRelation(SysUserRole relation) {
        if (relation == null) {
            throw new IllegalArgumentException("SysUserRole must not be null");
        }
        requirePositive(relation.getUserId(), "User ID");
        requirePositive(relation.getRoleId(), "Role ID");
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

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}

