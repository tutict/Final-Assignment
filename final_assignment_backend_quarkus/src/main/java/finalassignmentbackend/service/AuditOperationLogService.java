package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.AuditOperationLog;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.AuditOperationLogMapper;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
@RegisterForReflection
public class AuditOperationLogService {

    private static final Logger log = Logger.getLogger(AuditOperationLogService.class.getName());

    @Inject
    AuditOperationLogMapper auditOperationLogMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "auditOperationLogCache")
    @WsAction(service = "AuditOperationLogService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AuditOperationLog logRecord, String action) {
        Objects.requireNonNull(logRecord, "AuditOperationLog must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate audit operation log request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(logRecord.getLogId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "auditOperationLogCache")
    public AuditOperationLog createAuditOperationLog(AuditOperationLog logRecord) {
        validateLog(logRecord);
        auditOperationLogMapper.insert(logRecord);
        return logRecord;
    }

    @Transactional
    @CacheInvalidate(cacheName = "auditOperationLogCache")
    public AuditOperationLog updateAuditOperationLog(AuditOperationLog logRecord) {
        validateLogId(logRecord);
        int rows = auditOperationLogMapper.updateById(logRecord);
        if (rows == 0) {
            throw new IllegalStateException("Audit operation log not found: " + logRecord.getLogId());
        }
        return logRecord;
    }

    @Transactional
    @CacheInvalidate(cacheName = "auditOperationLogCache")
    public void deleteAuditOperationLog(Long logId) {
        validateLogId(logId);
        int rows = auditOperationLogMapper.deleteById(logId);
        if (rows == 0) {
            throw new IllegalStateException("Audit operation log not found: " + logId);
        }
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public AuditOperationLog findById(Long logId) {
        validateLogId(logId);
        return auditOperationLogMapper.selectById(logId);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> findAll() {
        return auditOperationLogMapper.selectList(null);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> searchByModule(String module, int page, int size) {
        if (isBlank(module)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.like("operation_module", module)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> searchByOperationType(String type, int page, int size) {
        if (isBlank(type)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("operation_type", type)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> findByUserId(Long userId, int page, int size) {
        if (userId == null || userId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> searchByOperationTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.between("operation_time", start, end)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> searchByUsername(String username, int page, int size) {
        if (isBlank(username)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.like("username", username)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> searchByRequestUrl(String requestUrl, int page, int size) {
        if (isBlank(requestUrl)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.like("request_url", requestUrl)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> searchByRequestMethod(String requestMethod, int page, int size) {
        if (isBlank(requestMethod)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("request_method", requestMethod)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditOperationLogCache")
    public List<AuditOperationLog> searchByOperationResult(String operationResult, int page, int size) {
        if (isBlank(operationResult)) {
            return List.of();
        }
        validatePagination(page, size);
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

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

    private List<AuditOperationLog> fetchFromDatabase(QueryWrapper<AuditOperationLog> wrapper, int page, int size) {
        Page<AuditOperationLog> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        auditOperationLogMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
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

    private void validateLog(AuditOperationLog logRecord) {
        if (logRecord == null) {
            throw new IllegalArgumentException("Audit operation log must not be null");
        }
        if (logRecord.getOperationTime() == null) {
            logRecord.setOperationTime(LocalDateTime.now());
        }
    }

    private void validateLogId(AuditOperationLog logRecord) {
        validateLog(logRecord);
        validateLogId(logRecord.getLogId());
    }

    private void validateLogId(Long logId) {
        if (logId == null || logId <= 0) {
            throw new IllegalArgumentException("Invalid log ID: " + logId);
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
