package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.AuditLoginLog;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.AuditLoginLogMapper;
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
public class AuditLoginLogService {

    private static final Logger log = Logger.getLogger(AuditLoginLogService.class.getName());

    @Inject
    AuditLoginLogMapper auditLoginLogMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "auditLoginLogCache")
    @WsAction(service = "AuditLoginLogService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AuditLoginLog logRecord, String action) {
        Objects.requireNonNull(logRecord, "AuditLoginLog must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate login log request detected");
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
    @CacheInvalidate(cacheName = "auditLoginLogCache")
    public AuditLoginLog createAuditLoginLog(AuditLoginLog logRecord) {
        validateLog(logRecord);
        auditLoginLogMapper.insert(logRecord);
        return logRecord;
    }

    @Transactional
    @CacheInvalidate(cacheName = "auditLoginLogCache")
    public AuditLoginLog updateAuditLoginLog(AuditLoginLog logRecord) {
        validateLogId(logRecord);
        int rows = auditLoginLogMapper.updateById(logRecord);
        if (rows == 0) {
            throw new IllegalStateException("Login log not found: " + logRecord.getLogId());
        }
        return logRecord;
    }

    @Transactional
    @CacheInvalidate(cacheName = "auditLoginLogCache")
    public void deleteAuditLoginLog(Long logId) {
        validateLogId(logId);
        int rows = auditLoginLogMapper.deleteById(logId);
        if (rows == 0) {
            throw new IllegalStateException("Login log not found: " + logId);
        }
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public AuditLoginLog findById(Long logId) {
        validateLogId(logId);
        return auditLoginLogMapper.selectById(logId);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> findAll() {
        return auditLoginLogMapper.selectList(null);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> searchByUsername(String username, int page, int size) {
        if (isBlank(username)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.likeRight("username", username)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> searchByLoginResult(String result, int page, int size) {
        if (isBlank(result)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.eq("login_result", result)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> searchByLoginTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.between("login_time", start, end)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> searchByLoginIp(String ip, int page, int size) {
        if (isBlank(ip)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.likeRight("login_ip", ip)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> searchByLoginLocation(String loginLocation, int page, int size) {
        if (isBlank(loginLocation)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.likeRight("login_location", loginLocation)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> searchByDeviceType(String deviceType, int page, int size) {
        if (isBlank(deviceType)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.eq("device_type", deviceType)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> searchByBrowserType(String browserType, int page, int size) {
        if (isBlank(browserType)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.eq("browser_type", browserType)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "auditLoginLogCache")
    public List<AuditLoginLog> searchByLogoutTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.between("logout_time", start, end)
                .orderByDesc("logout_time");
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

    private List<AuditLoginLog> fetchFromDatabase(QueryWrapper<AuditLoginLog> wrapper, int page, int size) {
        Page<AuditLoginLog> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        auditLoginLogMapper.selectPage(mpPage, wrapper);
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

    private void validateLog(AuditLoginLog logRecord) {
        if (logRecord == null) {
            throw new IllegalArgumentException("AuditLoginLog must not be null");
        }
        if (isBlank(logRecord.getUsername())) {
            throw new IllegalArgumentException("Username must not be blank");
        }
    }

    private void validateLogId(AuditLoginLog logRecord) {
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
