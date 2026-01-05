package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.SysRole;
import com.tutict.finalassignmentbackend.entity.elastic.SysRoleDocument;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.SysRoleMapper;
import com.tutict.finalassignmentbackend.repository.SysRoleSearchRepository;
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
public class SysRoleService {

    private static final Logger log = Logger.getLogger(SysRoleService.class.getName());
    private static final String CACHE_NAME = "sysRoleCache";

    private final SysRoleMapper sysRoleMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysRoleSearchRepository sysRoleSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysRoleService(SysRoleMapper sysRoleMapper,
                          SysRequestHistoryMapper sysRequestHistoryMapper,
                          SysRoleSearchRepository sysRoleSearchRepository,
                          KafkaTemplate<String, String> kafkaTemplate,
                          ObjectMapper objectMapper) {
        this.sysRoleMapper = sysRoleMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysRoleSearchRepository = sysRoleSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysRoleService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysRole sysRole, String action) {
        Objects.requireNonNull(sysRole, "SysRole must not be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            log.warning(() -> String.format("Duplicate sys role request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate sys role request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("sys_role_" + action, idempotencyKey, sysRole);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(Optional.ofNullable(sysRole.getRoleId()).map(Integer::longValue).orElse(null));
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysRole createSysRole(SysRole sysRole) {
        validateSysRole(sysRole);
        sysRoleMapper.insert(sysRole);
        syncToIndexAfterCommit(sysRole);
        return sysRole;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysRole updateSysRole(SysRole sysRole) {
        validateSysRole(sysRole);
        requirePositive(sysRole.getRoleId());
        int rows = sysRoleMapper.updateById(sysRole);
        if (rows == 0) {
            throw new IllegalStateException("SysRole not found for id=" + sysRole.getRoleId());
        }
        syncToIndexAfterCommit(sysRole);
        return sysRole;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteSysRole(Integer roleId) {
        requirePositive(roleId);
        int rows = sysRoleMapper.deleteById(roleId);
        if (rows == 0) {
            throw new IllegalStateException("SysRole not found for id=" + roleId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysRoleSearchRepository.deleteById(roleId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#roleId", unless = "#result == null")
    public SysRole findById(Integer roleId) {
        requirePositive(roleId);
        return sysRoleSearchRepository.findById(roleId)
                .map(SysRoleDocument::toEntity)
                .orElseGet(() -> {
                    SysRole entity = sysRoleMapper.selectById(roleId);
                    if (entity != null) {
                        sysRoleSearchRepository.save(SysRoleDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<SysRole> findAll() {
        List<SysRole> fromIndex = StreamSupport.stream(sysRoleSearchRepository.findAll().spliterator(), false)
                .map(SysRoleDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<SysRole> fromDb = sysRoleMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'code:' + #roleCode", unless = "#result == null")
    public SysRole findByRoleCode(String roleCode) {
        if (isBlank(roleCode)) {
            return null;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("role_code", roleCode);
        SysRole fromDb = sysRoleMapper.selectOne(wrapper);
        if (fromDb != null) {
            syncToIndexAfterCommit(fromDb);
        }
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'roleCodePrefix:' + #roleCode + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysRole> searchByRoleCodePrefix(String roleCode, int page, int size) {
        if (isBlank(roleCode)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRole> index = mapHits(sysRoleSearchRepository.searchByRoleCodePrefix(roleCode, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.likeRight("role_code", roleCode);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'roleCodeFuzzy:' + #roleCode + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysRole> searchByRoleCodeFuzzy(String roleCode, int page, int size) {
        if (isBlank(roleCode)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRole> index = mapHits(sysRoleSearchRepository.searchByRoleCodeFuzzy(roleCode, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.like("role_code", roleCode);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'roleNamePrefix:' + #roleName + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysRole> searchByRoleNamePrefix(String roleName, int page, int size) {
        if (isBlank(roleName)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRole> index = mapHits(sysRoleSearchRepository.searchByRoleNamePrefix(roleName, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.likeRight("role_name", roleName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'roleNameFuzzy:' + #roleName + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysRole> searchByRoleNameFuzzy(String roleName, int page, int size) {
        if (isBlank(roleName)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRole> index = mapHits(sysRoleSearchRepository.searchByRoleNameFuzzy(roleName, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.like("role_name", roleName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'roleType:' + #roleType + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysRole> searchByRoleType(String roleType, int page, int size) {
        if (isBlank(roleType)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRole> index = mapHits(sysRoleSearchRepository.searchByRoleType(roleType, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("role_type", roleType);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'dataScope:' + #dataScope + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysRole> searchByDataScope(String dataScope, int page, int size) {
        if (isBlank(dataScope)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRole> index = mapHits(sysRoleSearchRepository.searchByDataScope(dataScope, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("data_scope", dataScope);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #status + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysRole> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRole> index = mapHits(sysRoleSearchRepository.searchByStatus(status, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return fetchFromDatabase(wrapper, page, size);
    }
    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Integer roleId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(roleId != null ? roleId.longValue() : null);
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

    private void sendKafkaMessage(String topic, String idempotencyKey, SysRole sysRole) {
        try {
            String payload = objectMapper.writeValueAsString(sysRole);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send SysRole Kafka message", ex);
            throw new RuntimeException("Failed to send sys role event", ex);
        }
    }

    private void syncToIndexAfterCommit(SysRole sysRole) {
        if (sysRole == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysRoleDocument doc = SysRoleDocument.fromEntity(sysRole);
                if (doc != null) {
                    sysRoleSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysRole> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysRoleDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysRoleDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysRoleSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private void validateSysRole(SysRole sysRole) {
        if (sysRole == null) {
            throw new IllegalArgumentException("SysRole must not be null");
        }
        if (isBlank(sysRole.getRoleCode())) {
            throw new IllegalArgumentException("Role code must not be blank");
        }
        if (isBlank(sysRole.getRoleName())) {
            throw new IllegalArgumentException("Role name must not be blank");
        }
        if (sysRole.getCreatedAt() == null) {
            sysRole.setCreatedAt(LocalDateTime.now());
        }
        if (sysRole.getUpdatedAt() == null) {
            sysRole.setUpdatedAt(LocalDateTime.now());
        }
        if (isBlank(sysRole.getStatus())) {
            sysRole.setStatus("Active");
        }
    }

    private List<SysRole> fetchFromDatabase(QueryWrapper<SysRole> wrapper, int page, int size) {
        Page<SysRole> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRoleMapper.selectPage(mpPage, wrapper);
        List<SysRole> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private List<SysRole> mapHits(org.springframework.data.elasticsearch.core.SearchHits<SysRoleDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(SysRoleDocument::toEntity)
                .collect(Collectors.toList());
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Role ID" + " must be greater than zero");
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
