package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysBackupRestore;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.SysBackupRestoreMapper;
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
public class SysBackupRestoreService {

    private static final Logger log = Logger.getLogger(SysBackupRestoreService.class.getName());

    @Inject
    SysBackupRestoreMapper sysBackupRestoreMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysBackupRestoreCache")
    @WsAction(service = "SysBackupRestoreService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysBackupRestore record, String action) {
        Objects.requireNonNull(record, "SysBackupRestore must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate backup request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(record.getBackupId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysBackupRestoreCache")
    public SysBackupRestore createSysBackupRestore(SysBackupRestore record) {
        validateRecord(record);
        sysBackupRestoreMapper.insert(record);
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysBackupRestoreCache")
    public SysBackupRestore updateSysBackupRestore(SysBackupRestore record) {
        validateRecordId(record);
        int rows = sysBackupRestoreMapper.updateById(record);
        if (rows == 0) {
            throw new IllegalStateException("Backup task not found: " + record.getBackupId());
        }
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysBackupRestoreCache")
    public void deleteSysBackupRestore(Long backupId) {
        validateRecordId(backupId);
        int rows = sysBackupRestoreMapper.deleteById(backupId);
        if (rows == 0) {
            throw new IllegalStateException("Backup task not found: " + backupId);
        }
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public SysBackupRestore findById(Long backupId) {
        validateRecordId(backupId);
        return sysBackupRestoreMapper.selectById(backupId);
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public List<SysBackupRestore> findAll() {
        return sysBackupRestoreMapper.selectList(null);
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public List<SysBackupRestore> searchByBackupType(String backupType, int page, int size) {
        if (isBlank(backupType)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysBackupRestore> wrapper = new QueryWrapper<>();
        wrapper.eq("backup_type", backupType);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public List<SysBackupRestore> searchByBackupFileNamePrefix(String backupFileName, int page, int size) {
        if (isBlank(backupFileName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysBackupRestore> wrapper = new QueryWrapper<>();
        wrapper.likeRight("backup_file_name", backupFileName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public List<SysBackupRestore> searchByBackupHandler(String backupHandler, int page, int size) {
        if (isBlank(backupHandler)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysBackupRestore> wrapper = new QueryWrapper<>();
        wrapper.likeRight("backup_handler", backupHandler);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public List<SysBackupRestore> searchByRestoreStatus(String restoreStatus, int page, int size) {
        if (isBlank(restoreStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysBackupRestore> wrapper = new QueryWrapper<>();
        wrapper.eq("restore_status", restoreStatus);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public List<SysBackupRestore> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysBackupRestore> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public List<SysBackupRestore> searchByBackupTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<SysBackupRestore> wrapper = new QueryWrapper<>();
        wrapper.between("backup_time", start, end);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysBackupRestoreCache")
    public List<SysBackupRestore> searchByRestoreTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<SysBackupRestore> wrapper = new QueryWrapper<>();
        wrapper.between("restore_time", start, end);
        return fetchFromDatabase(wrapper, page, size);
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

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

    private List<SysBackupRestore> fetchFromDatabase(QueryWrapper<SysBackupRestore> wrapper, int page, int size) {
        Page<SysBackupRestore> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysBackupRestoreMapper.selectPage(mpPage, wrapper);
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

    private void validateRecord(SysBackupRestore record) {
        if (record == null) {
            throw new IllegalArgumentException("SysBackupRestore must not be null");
        }
        if (isBlank(record.getBackupType())) {
            throw new IllegalArgumentException("Backup type must not be blank");
        }
    }

    private void validateRecordId(SysBackupRestore record) {
        validateRecord(record);
        validateRecordId(record.getBackupId());
    }

    private void validateRecordId(Long backupId) {
        if (backupId == null || backupId <= 0) {
            throw new IllegalArgumentException("Invalid backup ID: " + backupId);
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
