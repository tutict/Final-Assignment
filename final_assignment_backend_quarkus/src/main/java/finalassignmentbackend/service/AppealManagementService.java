package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.AppealRecord;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.AppealRecordMapper;
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
public class AppealManagementService {

    private static final Logger log = Logger.getLogger(AppealManagementService.class.getName());

    @Inject
    AppealRecordMapper appealRecordMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    @WsAction(service = "AppealManagementService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        Objects.requireNonNull(appealRecord, "Appeal record cannot be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate appeal request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(appealRecord.getAppealId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        validateAppeal(appealRecord);
        appealRecordMapper.insert(appealRecord);
        return appealRecord;
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        validateAppealId(appealRecord);
        int rows = appealRecordMapper.updateById(appealRecord);
        if (rows == 0) {
            throw new IllegalStateException("Appeal not found: " + appealRecord.getAppealId());
        }
        return appealRecord;
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public AppealRecord updateProcessStatus(Long appealId, finalassignmentbackend.config.statemachine.states.AppealProcessState newState) {
        validateAppealId(appealId);
        if (newState == null) {
            throw new IllegalArgumentException("Process state must not be null");
        }
        AppealRecord record = appealRecordMapper.selectById(appealId);
        if (record == null) {
            throw new IllegalStateException("Appeal not found: " + appealId);
        }
        record.setProcessStatus(newState.getCode());
        record.setUpdatedAt(LocalDateTime.now());
        appealRecordMapper.updateById(record);
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    @WsAction(service = "AppealManagementService", action = "deleteAppeal")
    public void deleteAppeal(Long appealId) {
        validateAppealId(appealId);
        int rows = appealRecordMapper.deleteById(appealId);
        if (rows == 0) {
            throw new IllegalStateException("Appeal not found: " + appealId);
        }
    }

    @CacheResult(cacheName = "appealCache")
    @WsAction(service = "AppealManagementService", action = "getAppealById")
    public AppealRecord getAppealById(Long appealId) {
        validateAppealId(appealId);
        return appealRecordMapper.selectById(appealId);
    }

    @CacheResult(cacheName = "appealCache")
    @WsAction(service = "AppealManagementService", action = "findByOffenseId")
    public List<AppealRecord> findByOffenseId(Long offenseId, int page, int size) {
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_id", offenseId)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByAppealNumberPrefix(String appealNumber, int page, int size) {
        if (isBlank(appealNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appeal_number", appealNumber)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByAppealNumberFuzzy(String appealNumber, int page, int size) {
        if (isBlank(appealNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.like("appeal_number", appealNumber)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByAppellantNamePrefix(String appellantName, int page, int size) {
        if (isBlank(appellantName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appellant_name", appellantName)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByAppellantNameFuzzy(String appellantName, int page, int size) {
        if (isBlank(appellantName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.like("appellant_name", appellantName)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByAppellantIdCard(String appellantIdCard, int page, int size) {
        if (isBlank(appellantIdCard)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appellant_id_card", appellantIdCard)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByAcceptanceStatus(String acceptanceStatus, int page, int size) {
        if (isBlank(acceptanceStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("acceptance_status", acceptanceStatus)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByProcessStatus(String processStatus, int page, int size) {
        if (isBlank(processStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("process_status", processStatus)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByAppealTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.between("appeal_time", start, end)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, int page, int size) {
        if (isBlank(acceptanceHandler)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("acceptance_handler", acceptanceHandler)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long appealId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(appealId);
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

    private List<AppealRecord> fetchFromDatabase(QueryWrapper<AppealRecord> wrapper, int page, int size) {
        Page<AppealRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        appealRecordMapper.selectPage(mpPage, wrapper);
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

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void validateAppeal(AppealRecord appealRecord) {
        if (appealRecord == null) {
            throw new IllegalArgumentException("Appeal record cannot be null");
        }
        if (appealRecord.getOffenseId() == null) {
            throw new IllegalArgumentException("Offense ID is required");
        }
    }

    private void validateAppealId(AppealRecord appealRecord) {
        validateAppeal(appealRecord);
        validateAppealId(appealRecord.getAppealId());
    }

    private void validateAppealId(Long appealId) {
        if (appealId == null || appealId <= 0) {
            throw new IllegalArgumentException("Invalid appeal ID: " + appealId);
        }
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
