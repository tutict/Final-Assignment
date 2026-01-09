package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.DeductionRecord;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.DeductionRecordMapper;
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
public class DeductionRecordService {

    private static final Logger log = Logger.getLogger(DeductionRecordService.class.getName());

    @Inject
    DeductionRecordMapper deductionRecordMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "deductionRecordCache")
    @WsAction(service = "DeductionRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DeductionRecord record, String action) {
        Objects.requireNonNull(record, "Deduction record must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate deduction record request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(record.getDeductionId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionRecordCache")
    public DeductionRecord createDeductionRecord(DeductionRecord record) {
        validateRecord(record);
        deductionRecordMapper.insert(record);
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionRecordCache")
    public DeductionRecord updateDeductionRecord(DeductionRecord record) {
        validateRecordId(record);
        int rows = deductionRecordMapper.updateById(record);
        if (rows == 0) {
            throw new IllegalStateException("Deduction record not found: " + record.getDeductionId());
        }
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionRecordCache")
    public void deleteDeductionRecord(Long deductionId) {
        validateRecordId(deductionId);
        int rows = deductionRecordMapper.deleteById(deductionId);
        if (rows == 0) {
            throw new IllegalStateException("Deduction record not found: " + deductionId);
        }
    }

    @CacheResult(cacheName = "deductionRecordCache")
    public DeductionRecord findById(Long deductionId) {
        validateRecordId(deductionId);
        return deductionRecordMapper.selectById(deductionId);
    }

    @CacheResult(cacheName = "deductionRecordCache")
    public List<DeductionRecord> findAll() {
        return deductionRecordMapper.selectList(null);
    }

    @CacheResult(cacheName = "deductionRecordCache")
    public List<DeductionRecord> findByDriverId(Long driverId, int page, int size) {
        if (driverId == null || driverId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "deductionRecordCache")
    public List<DeductionRecord> findByOffenseId(Long offenseId, int page, int size) {
        if (offenseId == null || offenseId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_id", offenseId)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "deductionRecordCache")
    public List<DeductionRecord> searchByHandlerPrefix(String handler, int page, int size) {
        if (isBlank(handler)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("handler", handler)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "deductionRecordCache")
    public List<DeductionRecord> searchByHandlerFuzzy(String handler, int page, int size) {
        if (isBlank(handler)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.like("handler", handler)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "deductionRecordCache")
    public List<DeductionRecord> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "deductionRecordCache")
    public List<DeductionRecord> searchByDeductionTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.between("deduction_time", start, end)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long deductionId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(deductionId);
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

    private List<DeductionRecord> fetchFromDatabase(QueryWrapper<DeductionRecord> wrapper, int page, int size) {
        Page<DeductionRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        deductionRecordMapper.selectPage(mpPage, wrapper);
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

    private void validateRecord(DeductionRecord record) {
        if (record == null) {
            throw new IllegalArgumentException("Deduction record must not be null");
        }
        if (record.getDeductionTime() == null) {
            record.setDeductionTime(LocalDateTime.now());
        }
        if (record.getStatus() == null || record.getStatus().isBlank()) {
            record.setStatus("Pending");
        }
    }

    private void validateRecordId(DeductionRecord record) {
        validateRecord(record);
        validateRecordId(record.getDeductionId());
    }

    private void validateRecordId(Long deductionId) {
        if (deductionId == null || deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID: " + deductionId);
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
