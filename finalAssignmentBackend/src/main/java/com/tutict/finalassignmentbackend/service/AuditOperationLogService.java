package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.AuditOperationLog;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.AuditOperationLogDocument;
import com.tutict.finalassignmentbackend.mapper.AuditOperationLogMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.AuditOperationLogSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class AuditOperationLogService {

    private static final Logger log = Logger.getLogger(AuditOperationLogService.class.getName());
    private static final String CACHE_NAME = "auditOperationLogCache";

    private final AuditOperationLogMapper auditOperationLogMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final AuditOperationLogSearchRepository auditOperationLogSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public AuditOperationLogService(AuditOperationLogMapper auditOperationLogMapper,
                                    SysRequestHistoryMapper sysRequestHistoryMapper,
                                    AuditOperationLogSearchRepository auditOperationLogSearchRepository,
                                    KafkaTemplate<String, String> kafkaTemplate,
                                    ObjectMapper objectMapper) {
        this.auditOperationLogMapper = auditOperationLogMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.auditOperationLogSearchRepository = auditOperationLogSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "AuditOperationLogService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AuditOperationLog auditOperationLog, String action) {
        Objects.requireNonNull(auditOperationLog, "AuditOperationLog must not be null");
        if (sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey) != null) {
            throw new RuntimeException("Duplicate audit operation log request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("audit_operation_log_" + action, idempotencyKey, auditOperationLog);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(auditOperationLog.getLogId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public AuditOperationLog createAuditOperationLog(AuditOperationLog auditOperationLog) {
        validateAuditOperationLog(auditOperationLog);
        auditOperationLogMapper.insert(auditOperationLog);
        syncToIndexAfterCommit(auditOperationLog);
        return auditOperationLog;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public AuditOperationLog updateAuditOperationLog(AuditOperationLog auditOperationLog) {
        validateAuditOperationLog(auditOperationLog);
        requirePositive(auditOperationLog.getLogId(), "Log ID");
        int rows = auditOperationLogMapper.updateById(auditOperationLog);
        if (rows == 0) {
            throw new IllegalStateException("Audit operation log not found for id=" + auditOperationLog.getLogId());
        }
        syncToIndexAfterCommit(auditOperationLog);
        return auditOperationLog;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteAuditOperationLog(Long logId) {
        requirePositive(logId, "Log ID");
        int rows = auditOperationLogMapper.deleteById(logId);
        if (rows == 0) {
            throw new IllegalStateException("Audit operation log not found for id=" + logId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                auditOperationLogSearchRepository.deleteById(logId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#logId", unless = "#result == null")
    public AuditOperationLog findById(Long logId) {
        requirePositive(logId, "Log ID");
        return auditOperationLogSearchRepository.findById(logId)
                .map(AuditOperationLogDocument::toEntity)
                .orElseGet(() -> {
                    AuditOperationLog entity = auditOperationLogMapper.selectById(logId);
                    if (entity != null) {
                        auditOperationLogSearchRepository.save(AuditOperationLogDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> findAll() {
        List<AuditOperationLog> fromIndex = StreamSupport.stream(auditOperationLogSearchRepository.findAll().spliterator(), false)
                .map(AuditOperationLogDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<AuditOperationLog> fromDb = auditOperationLogMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'module:' + #module + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByModule(String module, int page, int size) {
        if (isBlank(module)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(auditOperationLogSearchRepository.searchByOperationModule(module, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.like("operation_module", module)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'type:' + #type + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByOperationType(String type, int page, int size) {
        if (isBlank(type)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(auditOperationLogSearchRepository.searchByOperationType(type, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("operation_type", type)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'user:' + #userId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> findByUserId(Long userId, int page, int size) {
        requirePositive(userId, "User ID");
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(auditOperationLogSearchRepository.findByUserId(userId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'timeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByOperationTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        List<AuditOperationLog> index = mapHits(auditOperationLogSearchRepository.searchByOperationTimeRange(startTime, endTime, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.between("operation_time", start, end)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'username:' + #username + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByUsername(String username, int page, int size) {
        if (isBlank(username)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(auditOperationLogSearchRepository.searchByUsername(username, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.like("username", username)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'requestUrl:' + #requestUrl + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByRequestUrl(String requestUrl, int page, int size) {
        if (isBlank(requestUrl)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(auditOperationLogSearchRepository.searchByRequestUrl(requestUrl, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.like("request_url", requestUrl)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'requestMethod:' + #requestMethod + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByRequestMethod(String requestMethod, int page, int size) {
        if (isBlank(requestMethod)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(auditOperationLogSearchRepository.searchByRequestMethod(requestMethod, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("request_method", requestMethod)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'result:' + #operationResult + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByOperationResult(String operationResult, int page, int size) {
        if (isBlank(operationResult)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(auditOperationLogSearchRepository.searchByOperationResult(operationResult, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("operation_result", operationResult)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long logId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(logId);
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

    private void sendKafkaMessage(String topic, String idempotencyKey, AuditOperationLog auditOperationLog) {
        try {
            String payload = objectMapper.writeValueAsString(auditOperationLog);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send AuditOperationLog Kafka message", ex);
            throw new RuntimeException("Failed to send AuditOperationLog event", ex);
        }
    }

    private void syncToIndexAfterCommit(AuditOperationLog auditOperationLog) {
        if (auditOperationLog == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                AuditOperationLogDocument doc = AuditOperationLogDocument.fromEntity(auditOperationLog);
                if (doc != null) {
                    auditOperationLogSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<AuditOperationLog> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<AuditOperationLogDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(AuditOperationLogDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    auditOperationLogSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private List<AuditOperationLog> fetchFromDatabase(QueryWrapper<AuditOperationLog> wrapper, int page, int size) {
        Page<AuditOperationLog> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        auditOperationLogMapper.selectPage(mpPage, wrapper);
        List<AuditOperationLog> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private List<AuditOperationLog> mapHits(SearchHits<AuditOperationLogDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(SearchHit::getContent)
                .map(AuditOperationLogDocument::toEntity)
                .collect(Collectors.toList());
    }

    private Pageable pageable(int page, int size) {
        return PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validateAuditOperationLog(AuditOperationLog auditOperationLog) {
        if (auditOperationLog == null) {
            throw new IllegalArgumentException("Audit operation log must not be null");
        }
        if (auditOperationLog.getOperationTime() == null) {
            auditOperationLog.setOperationTime(LocalDateTime.now());
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

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            log.log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
            return null;
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
