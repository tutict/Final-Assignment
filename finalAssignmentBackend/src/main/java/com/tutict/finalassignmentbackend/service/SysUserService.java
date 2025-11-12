package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.entity.elastic.SysUserDocument;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.SysUserMapper;
import com.tutict.finalassignmentbackend.repository.SysUserSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class SysUserService {

    private static final Logger LOG = Logger.getLogger(SysUserService.class.getName());
    private static final String CACHE_NAME = "sysUserCache";

    private final SysUserMapper sysUserMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysUserSearchRepository sysUserSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysUserService(SysUserMapper sysUserMapper,
                          SysRequestHistoryMapper sysRequestHistoryMapper,
                          SysUserSearchRepository sysUserSearchRepository,
                          KafkaTemplate<String, String> kafkaTemplate,
                          ObjectMapper objectMapper) {
        this.sysUserMapper = sysUserMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysUserSearchRepository = sysUserSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysUserService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysUser sysUser, String action) {
        Objects.requireNonNull(sysUser, "SysUser must not be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            LOG.warning(() -> String.format("Duplicate sys user request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate sys user request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("sys_user_" + action, idempotencyKey, sysUser);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(sysUser.getUserId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysUser createSysUser(SysUser sysUser) {
        validateSysUser(sysUser);
        sysUserMapper.insert(sysUser);
        syncToIndexAfterCommit(sysUser);
        return sysUser;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysUser updateSysUser(SysUser sysUser) {
        validateSysUser(sysUser);
        requirePositive(sysUser.getUserId(), "User ID");
        int rows = sysUserMapper.updateById(sysUser);
        if (rows == 0) {
            throw new IllegalStateException("SysUser not found for id=" + sysUser.getUserId());
        }
        syncToIndexAfterCommit(sysUser);
        return sysUser;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteSysUser(Long userId) {
        requirePositive(userId, "User ID");
        int rows = sysUserMapper.deleteById(userId);
        if (rows == 0) {
            throw new IllegalStateException("SysUser not found for id=" + userId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysUserSearchRepository.deleteById(userId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#userId", unless = "#result == null")
    public SysUser findById(Long userId) {
        requirePositive(userId, "User ID");
        return sysUserSearchRepository.findById(userId)
                .map(SysUserDocument::toEntity)
                .orElseGet(() -> {
                    SysUser entity = sysUserMapper.selectById(userId);
                    if (entity != null) {
                        sysUserSearchRepository.save(SysUserDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<SysUser> findAll() {
        List<SysUser> fromIndex = StreamSupport.stream(
                        sysUserSearchRepository.findAll().spliterator(), false)
                .map(SysUserDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<SysUser> fromDb = sysUserMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'username:' + #username", unless = "#result == null")
    public SysUser findByUsername(String username) {
        if (isBlank(username)) {
            return null;
        }
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("username", username);
        SysUser entity = sysUserMapper.selectOne(wrapper);
        if (entity != null) {
            syncToIndexAfterCommit(entity);
        }
        return entity;
    }

    public boolean isUsernameExists(String username) {
        if (isBlank(username)) {
            return false;
        }
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("username", username);
        return sysUserMapper.selectCount(wrapper) > 0;
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #status + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysUser> findByStatus(String status, int page, int size) {
        validatePagination(page, size);
        if (isBlank(status)) {
            return Collections.emptyList();
        }
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'dept:' + #department + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysUser> findByDepartment(String department, int page, int size) {
        validatePagination(page, size);
        if (isBlank(department)) {
            return Collections.emptyList();
        }
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("department", department);
        return fetchFromDatabase(wrapper, page, size);
    }

    public List<SysUser> getAllUsers() {
        return findAll();
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long userId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            LOG.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(userId);
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

    private List<SysUser> fetchFromDatabase(QueryWrapper<SysUser> wrapper, int page, int size) {
        Page<SysUser> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysUserMapper.selectPage(mpPage, wrapper);
        List<SysUser> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, SysUser sysUser) {
        try {
            String payload = objectMapper.writeValueAsString(sysUser);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Failed to send SysUser Kafka message", ex);
            throw new RuntimeException("Failed to send sys user event", ex);
        }
    }

    private void syncToIndexAfterCommit(SysUser sysUser) {
        if (sysUser == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysUserDocument doc = SysUserDocument.fromEntity(sysUser);
                if (doc != null) {
                    sysUserSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysUser> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysUserDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysUserDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysUserSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private void validateSysUser(SysUser sysUser) {
        if (sysUser == null) {
            throw new IllegalArgumentException("SysUser must not be null");
        }
        if (isBlank(sysUser.getUsername())) {
            throw new IllegalArgumentException("Username must not be blank");
        }
        if (isBlank(sysUser.getPassword())) {
            throw new IllegalArgumentException("Password must not be blank");
        }
        if (sysUser.getCreatedAt() == null) {
            sysUser.setCreatedAt(LocalDateTime.now());
        }
        if (sysUser.getUpdatedAt() == null) {
            sysUser.setUpdatedAt(LocalDateTime.now());
        }
        if (isBlank(sysUser.getStatus())) {
            sysUser.setStatus("Active");
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
