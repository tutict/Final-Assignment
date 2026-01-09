package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.OffenseRecord;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.OffenseRecordMapper;
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
public class OffenseRecordService {

    private static final Logger log = Logger.getLogger(OffenseRecordService.class.getName());

    @Inject
    OffenseRecordMapper offenseRecordMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    @WsAction(service = "OffenseRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseRecord record, String action) {
        Objects.requireNonNull(record, "Offense record must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate offense request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(record.getOffenseId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public OffenseRecord createOffenseRecord(OffenseRecord record) {
        validateRecord(record);
        offenseRecordMapper.insert(record);
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public OffenseRecord updateOffenseRecord(OffenseRecord record) {
        validateRecordId(record);
        int rows = offenseRecordMapper.updateById(record);
        if (rows == 0) {
            throw new IllegalStateException("Offense record not found: " + record.getOffenseId());
        }
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public OffenseRecord updateProcessStatus(Long offenseId, finalassignmentbackend.config.statemachine.states.OffenseProcessState newState) {
        validateRecordId(offenseId);
        OffenseRecord record = offenseRecordMapper.selectById(offenseId);
        if (record == null) {
            throw new IllegalStateException("Offense record not found: " + offenseId);
        }
        record.setProcessStatus(newState != null ? newState.getCode() : record.getProcessStatus());
        record.setUpdatedAt(LocalDateTime.now());
        offenseRecordMapper.updateById(record);
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseRecordCache")
    public void deleteOffenseRecord(Long offenseId) {
        validateRecordId(offenseId);
        int rows = offenseRecordMapper.deleteById(offenseId);
        if (rows == 0) {
            throw new IllegalStateException("Offense record not found: " + offenseId);
        }
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public OffenseRecord findById(Long offenseId) {
        validateRecordId(offenseId);
        return offenseRecordMapper.selectById(offenseId);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> findAll() {
        return offenseRecordMapper.selectList(null);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> findByDriverId(Long driverId, int page, int size) {
        if (driverId == null || driverId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> findByVehicleId(Long vehicleId, int page, int size) {
        if (vehicleId == null || vehicleId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("vehicle_id", vehicleId)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseCode(String offenseCode, int page, int size) {
        if (isBlank(offenseCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("offense_code", offenseCode)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByProcessStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("process_status", status)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.between("offense_time", start, end)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseNumber(String offenseNumber, int page, int size) {
        if (isBlank(offenseNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("offense_number", offenseNumber)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseLocation(String offenseLocation, int page, int size) {
        if (isBlank(offenseLocation)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("offense_location", offenseLocation)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseProvince(String offenseProvince, int page, int size) {
        if (isBlank(offenseProvince)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_province", offenseProvince)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByOffenseCity(String offenseCity, int page, int size) {
        if (isBlank(offenseCity)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_city", offenseCity)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByNotificationStatus(String notificationStatus, int page, int size) {
        if (isBlank(notificationStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("notification_status", notificationStatus)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByEnforcementAgency(String enforcementAgency, int page, int size) {
        if (isBlank(enforcementAgency)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("enforcement_agency", enforcementAgency)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseRecordCache")
    public List<OffenseRecord> searchByFineAmountRange(double minAmount, double maxAmount, int page, int size) {
        validatePagination(page, size);
        if (minAmount > maxAmount) {
            return List.of();
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.between("fine_amount", minAmount, maxAmount)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long offenseId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(offenseId);
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

    private List<OffenseRecord> fetchFromDatabase(QueryWrapper<OffenseRecord> wrapper, int page, int size) {
        Page<OffenseRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        offenseRecordMapper.selectPage(mpPage, wrapper);
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

    private void validateRecord(OffenseRecord record) {
        if (record == null) {
            throw new IllegalArgumentException("Offense record must not be null");
        }
        if (record.getOffenseTime() == null) {
            record.setOffenseTime(LocalDateTime.now());
        }
        if (record.getProcessStatus() == null || record.getProcessStatus().isBlank()) {
            record.setProcessStatus("Pending");
        }
    }

    private void validateRecordId(OffenseRecord record) {
        validateRecord(record);
        validateRecordId(record.getOffenseId());
    }

    private void validateRecordId(Long offenseId) {
        if (offenseId == null || offenseId <= 0) {
            throw new IllegalArgumentException("Invalid offense ID: " + offenseId);
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
