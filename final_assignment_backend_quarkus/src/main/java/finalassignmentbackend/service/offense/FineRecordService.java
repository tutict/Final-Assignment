package finalassignmentbackend.service.offense;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.FineRecord;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.FineRecordMapper;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import finalassignmentbackend.reliability.HistoryReserve;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
@RegisterForReflection
public class FineRecordService {

    private static final Logger log = Logger.getLogger(FineRecordService.class.getName());

    @Inject
    FineRecordMapper fineRecordMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "fineRecordCache")
    @WsAction(service = "FineRecordService", action = "checkAndInsertIdempotency", roles = {"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE"})
    public void checkAndInsertIdempotency(String idempotencyKey, FineRecord record, String action) {
        Objects.requireNonNull(record, "Fine record must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        HistoryReserve.reserve(sysRequestHistoryMapper, idempotencyKey, "FINE_" + action.toUpperCase(),
                HistoryReserve.sha256(record.getOffenseId() + "|" + record.getFineAmount() + "|"
                        + record.getDriverId() + "|" + record.getPaymentStatus()));
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineRecordCache")
    public FineRecord createFineRecord(FineRecord record) {
        validateRecord(record);
        fineRecordMapper.insert(record);
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineRecordCache")
    public FineRecord updateFineRecord(FineRecord record) {
        validateRecordId(record);
        int rows = fineRecordMapper.updateById(record);
        if (rows == 0) {
            throw new IllegalStateException("Fine record not found: " + record.getFineId());
        }
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineRecordCache")
    public void deleteFineRecord(Long fineId) {
        validateRecordId(fineId);
        int rows = fineRecordMapper.deleteById(fineId);
        if (rows == 0) {
            throw new IllegalStateException("Fine record not found: " + fineId);
        }
    }

    @CacheResult(cacheName = "fineRecordCache")
    public FineRecord findById(Long fineId) {
        validateRecordId(fineId);
        return fineRecordMapper.selectById(fineId);
    }

    public List<FineRecord> findAll() {
        return fineRecordMapper.selectList(null);
    }

    public List<FineRecord> findByOffenseId(Long offenseId, int page, int size) {
        if (offenseId == null || offenseId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_id", offenseId)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    public List<FineRecord> findByDriverId(Long driverId, int page, int size) {
        if (driverId == null || driverId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    public List<FineRecord> searchByHandlerPrefix(String handler, int page, int size) {
        if (isBlank(handler)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("handler", handler)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    public List<FineRecord> searchByHandlerFuzzy(String handler, int page, int size) {
        if (isBlank(handler)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.like("handler", handler)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    public List<FineRecord> searchByPaymentStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("payment_status", status)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    public List<FineRecord> searchByFineDateRange(String startDate, String endDate, int page, int size) {
        validatePagination(page, size);
        LocalDate start = parseDate(startDate, "startDate");
        LocalDate end = parseDate(endDate, "endDate");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.between("fine_date", start, end)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }


    public List<FineRecord> searchByPayee(String payee, int page, int size) {
        if (isBlank(payee)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.and(nested -> nested.like("handler", payee.trim())
                        .or()
                        .apply("driver_id IN (SELECT driver_id FROM driver_information WHERE name LIKE {0})",
                                "%" + payee.trim() + "%"))
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    public FineRecord findByReceiptNumber(String receiptNumber) {
        if (isBlank(receiptNumber)) {
            return null;
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("fine_number", receiptNumber.trim()).last("LIMIT 1");
        List<FineRecord> rows = fineRecordMapper.selectList(wrapper);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public List<FineRecord> searchByTimeRange(String startTime, String endTime, int maxSuggestions) {
        int size = maxSuggestions <= 0 ? 10 : Math.min(maxSuggestions, 100);
        return searchByFineDateRange(datePrefix(startTime), datePrefix(endTime), 1, size);
    }

    private String datePrefix(String value) {
        if (isBlank(value)) {
            return null;
        }
        String text = value.trim();
        return text.length() >= 10 ? text.substring(0, 10) : text;
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long fineId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(fineId);
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

    private List<FineRecord> fetchFromDatabase(QueryWrapper<FineRecord> wrapper, int page, int size) {
        Page<FineRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        fineRecordMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private LocalDate parseDate(String value, String fieldName) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDate.parse(value);
        } catch (DateTimeParseException ex) {
            log.log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
            return null;
        }
    }

    private void validateRecord(FineRecord record) {
        if (record == null) {
            throw new IllegalArgumentException("Fine record must not be null");
        }
        if (record.getOffenseId() == null || record.getOffenseId() <= 0) {
            throw new IllegalArgumentException("请选择关联的违法记录");
        }
        if (record.getFineNumber() == null || record.getFineNumber().isBlank()) {
            record.setFineNumber("FN" + System.currentTimeMillis());
        }
        if (record.getIssuingAuthority() == null || record.getIssuingAuthority().isBlank()) {
            record.setIssuingAuthority("未填写");
        }
        if (record.getHandler() == null || record.getHandler().isBlank()) {
            record.setHandler("系统");
        }
        if (record.getFineDate() == null) {
            record.setFineDate(LocalDate.now());
        }
        if (record.getPaymentStatus() == null || record.getPaymentStatus().isBlank()) {
            record.setPaymentStatus("Unpaid");
        }
    }

    private void validateRecordId(FineRecord record) {
        validateRecord(record);
        validateRecordId(record.getFineId());
    }

    private void validateRecordId(Long fineId) {
        if (fineId == null || fineId <= 0) {
            throw new IllegalArgumentException("Invalid fine ID: " + fineId);
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
