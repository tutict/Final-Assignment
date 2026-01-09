package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.PaymentRecord;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.PaymentRecordMapper;
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
public class PaymentRecordService {

    private static final Logger log = Logger.getLogger(PaymentRecordService.class.getName());

    @Inject
    PaymentRecordMapper paymentRecordMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "paymentRecordCache")
    @WsAction(service = "PaymentRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, PaymentRecord record, String action) {
        Objects.requireNonNull(record, "Payment record must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate payment record request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(record.getPaymentId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "paymentRecordCache")
    public PaymentRecord createPaymentRecord(PaymentRecord record) {
        validateRecord(record);
        paymentRecordMapper.insert(record);
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "paymentRecordCache")
    public PaymentRecord updatePaymentRecord(PaymentRecord record) {
        validateRecordId(record);
        int rows = paymentRecordMapper.updateById(record);
        if (rows == 0) {
            throw new IllegalStateException("Payment record not found: " + record.getPaymentId());
        }
        return record;
    }

    @Transactional
    @CacheInvalidate(cacheName = "paymentRecordCache")
    public void deletePaymentRecord(Long paymentId) {
        validateRecordId(paymentId);
        int rows = paymentRecordMapper.deleteById(paymentId);
        if (rows == 0) {
            throw new IllegalStateException("Payment record not found: " + paymentId);
        }
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public PaymentRecord findById(Long paymentId) {
        validateRecordId(paymentId);
        return paymentRecordMapper.selectById(paymentId);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> findAll() {
        return paymentRecordMapper.selectList(null);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> findByFineId(Long fineId, int page, int size) {
        if (fineId == null || fineId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("fine_id", fineId)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> searchByPayerIdCard(String idCard, int page, int size) {
        if (isBlank(idCard)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("payer_id_card", idCard)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> searchByPaymentStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("payment_status", status)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> searchByTransactionId(String transactionId, int page, int size) {
        if (isBlank(transactionId)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("transaction_id", transactionId)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> searchByPaymentNumber(String paymentNumber, int page, int size) {
        if (isBlank(paymentNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("payment_number", paymentNumber)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> searchByPayerName(String payerName, int page, int size) {
        if (isBlank(payerName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("payer_name", payerName)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> searchByPaymentMethod(String paymentMethod, int page, int size) {
        if (isBlank(paymentMethod)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("payment_method", paymentMethod)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> searchByPaymentChannel(String paymentChannel, int page, int size) {
        if (isBlank(paymentChannel)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("payment_channel", paymentChannel)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "paymentRecordCache")
    public List<PaymentRecord> searchByPaymentTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.between("payment_time", start, end)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Transactional
    @CacheInvalidate(cacheName = "paymentRecordCache")
    public PaymentRecord updatePaymentStatus(Long paymentId, String status) {
        validateRecordId(paymentId);
        PaymentRecord record = paymentRecordMapper.selectById(paymentId);
        if (record == null) {
            throw new IllegalStateException("Payment record not found: " + paymentId);
        }
        record.setPaymentStatus(status);
        record.setUpdatedAt(LocalDateTime.now());
        paymentRecordMapper.updateById(record);
        return record;
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long paymentId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(paymentId);
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

    private List<PaymentRecord> fetchFromDatabase(QueryWrapper<PaymentRecord> wrapper, int page, int size) {
        Page<PaymentRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        paymentRecordMapper.selectPage(mpPage, wrapper);
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

    private void validateRecord(PaymentRecord record) {
        if (record == null) {
            throw new IllegalArgumentException("Payment record must not be null");
        }
        if (record.getFineId() == null) {
            throw new IllegalArgumentException("Fine ID is required");
        }
        if (record.getPaymentTime() == null) {
            record.setPaymentTime(LocalDateTime.now());
        }
        if (record.getPaymentStatus() == null || record.getPaymentStatus().isBlank()) {
            record.setPaymentStatus("Pending");
        }
    }

    private void validateRecordId(PaymentRecord record) {
        validateRecord(record);
        validateRecordId(record.getPaymentId());
    }

    private void validateRecordId(Long paymentId) {
        if (paymentId == null || paymentId <= 0) {
            throw new IllegalArgumentException("Invalid payment ID: " + paymentId);
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
