package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.config.statemachine.states.PaymentState;
import com.tutict.finalassignmentbackend.entity.FineRecord;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.PaymentRecord;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.PaymentRecordDocument;
import com.tutict.finalassignmentbackend.exception.EntityNotFoundException;
import com.tutict.finalassignmentbackend.mapper.FineRecordMapper;
import com.tutict.finalassignmentbackend.mapper.PaymentRecordMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.payment.governance.PaymentGovernanceClassifier;
import com.tutict.finalassignmentbackend.payment.governance.PaymentGovernanceLogFactory;
import com.tutict.finalassignmentbackend.payment.exception.PaymentDuplicateRequestException;
import com.tutict.finalassignmentbackend.payment.exception.PaymentOptimisticLockException;
import com.tutict.finalassignmentbackend.payment.messaging.PaymentRecordKafkaEvent;
import com.tutict.finalassignmentbackend.service.events.PaymentStatusChangedEvent;
import com.tutict.finalassignmentbackend.repository.PaymentRecordSearchRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.dao.DataIntegrityViolationException;
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
public class PaymentRecordService {

    private static final Logger log = Logger.getLogger(PaymentRecordService.class.getName());
    private static final String CACHE_NAME = "paymentRecordCache";

    private final PaymentRecordMapper paymentRecordMapper;
    private final FineRecordMapper fineRecordMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final PaymentRecordSearchRepository paymentRecordSearchRepository;
    private final ApplicationEventPublisher applicationEventPublisher;
    private final PaymentGovernanceClassifier paymentGovernanceClassifier;

    @Autowired
    public PaymentRecordService(PaymentRecordMapper paymentRecordMapper,
                                FineRecordMapper fineRecordMapper,
                                SysRequestHistoryMapper sysRequestHistoryMapper,
                                PaymentRecordSearchRepository paymentRecordSearchRepository,
                                ApplicationEventPublisher applicationEventPublisher) {
        this.paymentRecordMapper = paymentRecordMapper;
        this.fineRecordMapper = fineRecordMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.paymentRecordSearchRepository = paymentRecordSearchRepository;
        this.applicationEventPublisher = applicationEventPublisher;
        this.paymentGovernanceClassifier = new PaymentGovernanceClassifier();
    }

    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "PaymentRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, PaymentRecord paymentRecord, String action) {
        Objects.requireNonNull(paymentRecord, "PaymentRecord must not be null");
        insertProcessingHistory(
                idempotencyKey,
                "PAYMENT_" + normalizeAction(action),
                "POST",
                "/api/payments",
                paymentRecord.getPaymentId(),
                "PROCESSING"
        );
    }

    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public PaymentRecord createPaymentRecord(PaymentRecord paymentRecord) {
        validatePaymentRecord(paymentRecord);
        paymentRecordMapper.insert(paymentRecord);
        syncToIndexAfterCommit(paymentRecord);
        return paymentRecord;
    }

    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public PaymentRecord createPaymentRecord(PaymentRecord paymentRecord, String idempotencyKey) {
        validatePaymentRecord(paymentRecord);
        SysRequestHistory history = insertProcessingHistory(
                idempotencyKey,
                "PAYMENT_CREATE",
                "POST",
                "/api/payments",
                paymentRecord.getPaymentId(),
                "PROCESSING"
        );
        paymentRecordMapper.insert(paymentRecord);
        applicationEventPublisher.publishEvent(
                new PaymentRecordKafkaEvent("payment_record_create", idempotencyKey, paymentRecord)
        );
        markHistorySuccess(history, paymentRecord.getPaymentId());
        syncToIndexAfterCommit(paymentRecord);
        return paymentRecord;
    }

    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public PaymentRecord updatePaymentRecord(PaymentRecord paymentRecord) {
        validatePaymentRecord(paymentRecord);
        requirePositive(paymentRecord.getPaymentId(), "Payment ID");
        int rows = paymentRecordMapper.updateById(paymentRecord);
        if (rows == 0) {
            throw new PaymentOptimisticLockException("Payment record was updated concurrently; refresh and retry");
        }
        syncToIndexAfterCommit(paymentRecord);
        publishPaymentStatusChanged(paymentRecord);
        return paymentRecord;
    }

    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public PaymentRecord updatePaymentRecord(PaymentRecord paymentRecord, String idempotencyKey) {
        validatePaymentRecord(paymentRecord);
        requirePositive(paymentRecord.getPaymentId(), "Payment ID");
        SysRequestHistory history = insertProcessingHistory(
                idempotencyKey,
                "PAYMENT_UPDATE",
                "PUT",
                "/api/payments/" + paymentRecord.getPaymentId(),
                paymentRecord.getPaymentId(),
                "PROCESSING"
        );
        int rows = paymentRecordMapper.updateById(paymentRecord);
        if (rows == 0) {
            throw new PaymentOptimisticLockException("Payment record was updated concurrently; refresh and retry");
        }
        applicationEventPublisher.publishEvent(
                new PaymentRecordKafkaEvent("payment_record_update", idempotencyKey, paymentRecord)
        );
        markHistorySuccess(history, paymentRecord.getPaymentId());
        syncToIndexAfterCommit(paymentRecord);
        publishPaymentStatusChanged(paymentRecord);
        return paymentRecord;
    }

    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public PaymentRecord updatePaymentStatus(Long paymentId, PaymentState newState) {
        return updatePaymentStatusInCurrentTransaction(paymentId, newState);
    }

    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public PaymentRecord updatePaymentStatus(Long paymentId, PaymentState newState, String idempotencyKey) {
        SysRequestHistory history = insertProcessingHistory(
                idempotencyKey,
                "PAYMENT_STATUS_UPDATE",
                "PUT",
                "/api/payments/" + paymentId + "/status/" + (newState == null ? "" : newState.getCode()),
                paymentId,
                "PROCESSING"
        );
        PaymentRecord updated = updatePaymentStatusInCurrentTransaction(paymentId, newState);
        markHistorySuccess(history, paymentId);
        return updated;
    }

    private PaymentRecord updatePaymentStatusInCurrentTransaction(Long paymentId, PaymentState newState) {
        requirePositive(paymentId, "Payment ID");
        PaymentRecord existing = paymentRecordMapper.selectById(paymentId);
        if (existing == null) {
            throw new EntityNotFoundException("PaymentRecord not found for id=" + paymentId);
        }
        logPaymentGovernance(PaymentGovernanceLogFactory.workflowStatus(
                paymentGovernanceClassifier.classifyWorkflowStatus(newState),
                existing,
                newState == null ? null : newState.getCode()
        ));
        existing.setPaymentStatus(newState != null ? newState.getCode() : existing.getPaymentStatus());
        existing.setUpdatedAt(LocalDateTime.now());
        int updated = paymentRecordMapper.updateById(existing);
        if (updated == 0) {
            throw new PaymentOptimisticLockException("Payment status was updated concurrently; refresh and retry");
        }
        syncToIndexAfterCommit(existing);
        publishPaymentStatusChanged(existing);
        return existing;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deletePaymentRecord(Long paymentId) {
        requirePositive(paymentId, "Payment ID");
        int rows = paymentRecordMapper.deleteById(paymentId);
        if (rows == 0) {
            throw new IllegalStateException("No PaymentRecord deleted for id=" + paymentId);
        }
        runAfterCommitOrNow(() -> paymentRecordSearchRepository.deleteById(paymentId));
    }

    private void runAfterCommitOrNow(Runnable action) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            action.run();
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                action.run();
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#paymentId", unless = "#result == null")
    public PaymentRecord findById(Long paymentId) {
        requirePositive(paymentId, "Payment ID");
        return paymentRecordSearchRepository.findById(paymentId)
                .map(PaymentRecordDocument::toEntity)
                .orElseGet(() -> {
                    PaymentRecord entity = paymentRecordMapper.selectById(paymentId);
                    if (entity != null) {
                        logReadRepairGovernance(entity.getPaymentId(), 1);
                        paymentRecordSearchRepository.save(PaymentRecordDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> findAll() {
        List<PaymentRecord> fromIndex = StreamSupport.stream(paymentRecordSearchRepository.findAll().spliterator(), false)
                .map(PaymentRecordDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<PaymentRecord> fromDb = paymentRecordMapper.selectList(null);
        logReadRepairGovernance(null, fromDb == null ? 0 : fromDb.size());
        fromDb.stream()
                .map(PaymentRecordDocument::fromEntity)
                .filter(Objects::nonNull)
                .forEach(paymentRecordSearchRepository::save);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'fine:' + #fineId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> findByFineId(Long fineId, int page, int size) {
        requirePositive(fineId, "Fine ID");
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.findByFineId(fineId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("fine_id", fineId)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'driver:' + #driverId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> findByDriverId(Long driverId, int page, int size) {
        requirePositive(driverId, "Driver ID");
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.findByDriverId(driverId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'payer:' + #payerIdCard + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> searchByPayerIdCard(String payerIdCard, int page, int size) {
        if (isBlank(payerIdCard)) {
            return List.of();
        }
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.searchByPayerIdCard(payerIdCard, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("payer_id_card", payerIdCard)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #paymentStatus + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> searchByPaymentStatus(String paymentStatus, int page, int size) {
        if (isBlank(paymentStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.searchByPaymentStatus(paymentStatus, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("payment_status", paymentStatus)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'txn:' + #transactionId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> searchByTransactionId(String transactionId, int page, int size) {
        if (isBlank(transactionId)) {
            return List.of();
        }
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.searchByTransactionId(transactionId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.like("transaction_id", transactionId)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'number:' + #paymentNumber + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> searchByPaymentNumber(String paymentNumber, int page, int size) {
        if (isBlank(paymentNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.searchByPaymentNumber(paymentNumber, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("payment_number", paymentNumber)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'payerName:' + #payerName + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> searchByPayerName(String payerName, int page, int size) {
        if (isBlank(payerName)) {
            return List.of();
        }
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.searchByPayerName(payerName, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("payer_name", payerName)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'method:' + #paymentMethod + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> searchByPaymentMethod(String paymentMethod, int page, int size) {
        if (isBlank(paymentMethod)) {
            return List.of();
        }
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.searchByPaymentMethod(paymentMethod, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("payment_method", paymentMethod)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'channel:' + #paymentChannel + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> searchByPaymentChannel(String paymentChannel, int page, int size) {
        if (isBlank(paymentChannel)) {
            return List.of();
        }
        validatePagination(page, size);
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.searchByPaymentChannel(paymentChannel, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("payment_channel", paymentChannel)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'timeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<PaymentRecord> searchByPaymentTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        List<PaymentRecord> index = mapHits(paymentRecordSearchRepository.searchByPaymentTimeRange(startTime, endTime, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<PaymentRecord> wrapper = new QueryWrapper<>();
        wrapper.between("payment_time", start, end)
                .orderByDesc("payment_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public boolean isDuplicateIdempotencyKey(String idempotencyKey) {
        return !isBlank(idempotencyKey) && sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey) != null;
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

    private void syncToIndexAfterCommit(PaymentRecord paymentRecord) {
        if (paymentRecord == null) {
            return;
        }
        runAfterCommitOrNow(() -> {
            PaymentRecordDocument doc = PaymentRecordDocument.fromEntity(paymentRecord);
            if (doc != null) {
                paymentRecordSearchRepository.save(doc);
            }
        });
    }

    private List<PaymentRecord> fetchFromDatabase(QueryWrapper<PaymentRecord> wrapper, int page, int size) {
        Page<PaymentRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        paymentRecordMapper.selectPage(mpPage, wrapper);
        List<PaymentRecord> records = mpPage.getRecords();
        logReadRepairGovernance(null, records == null ? 0 : records.size());
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private SysRequestHistory insertProcessingHistory(String idempotencyKey,
                                                      String businessType,
                                                      String requestMethod,
                                                      String requestUrl,
                                                      Long businessId,
                                                      String requestParams) {
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency-Key must not be blank");
        }
        if (sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey) != null) {
            throw new PaymentDuplicateRequestException("Duplicate payment request detected");
        }
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setRequestMethod(requestMethod);
        history.setRequestUrl(requestUrl);
        history.setRequestParams(requestParams);
        history.setBusinessType(businessType);
        history.setBusinessId(businessId);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        try {
            sysRequestHistoryMapper.insert(history);
        } catch (DataIntegrityViolationException ex) {
            throw new PaymentDuplicateRequestException("Duplicate payment request detected", ex);
        }
        return history;
    }

    private void markHistorySuccess(SysRequestHistory history, Long paymentId) {
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(paymentId);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private void validatePaymentRecord(PaymentRecord paymentRecord) {
        Objects.requireNonNull(paymentRecord, "PaymentRecord must not be null");
        if (paymentRecord.getFineId() == null) {
            throw new IllegalArgumentException("Fine ID must not be null");
        }
        if (paymentRecord.getPaymentTime() == null) {
            paymentRecord.setPaymentTime(LocalDateTime.now());
        }
        if (paymentRecord.getPaymentStatus() == null || paymentRecord.getPaymentStatus().isBlank()) {
            paymentRecord.setPaymentStatus("Pending");
        }
        if (paymentRecord.getFineId() != null) {
            FineRecord fine = fineRecordMapper.selectById(paymentRecord.getFineId());
            if (fine != null) {
                if (paymentRecord.getDriverId() == null) {
                    paymentRecord.setDriverId(fine.getDriverId());
                } else if (fine.getDriverId() != null && !Objects.equals(paymentRecord.getDriverId(), fine.getDriverId())) {
                    throw new IllegalArgumentException("Payment driver does not match fine owner");
                }
            }
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

    private String normalizeAction(String action) {
        return isBlank(action) ? "UNKNOWN" : action.trim().toUpperCase();
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }

    private void logReadRepairGovernance(Long paymentId, int recordCount) {
        if (recordCount <= 0) {
            return;
        }
        logPaymentGovernance(PaymentGovernanceLogFactory.readRepair(
                paymentGovernanceClassifier.classifyReadRepair(),
                paymentId,
                recordCount
        ));
    }

    private void logPaymentGovernance(String payload) {
        log.log(Level.INFO, payload);
    }

    private void syncBatchToIndexAfterCommit(List<PaymentRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        runAfterCommitOrNow(() -> {
            List<PaymentRecordDocument> documents = records.stream()
                    .filter(Objects::nonNull)
                    .map(PaymentRecordDocument::fromEntity)
                    .filter(Objects::nonNull)
                    .collect(Collectors.toList());
            if (!documents.isEmpty()) {
                paymentRecordSearchRepository.saveAll(documents);
            }
        });
    }

    private List<PaymentRecord> mapHits(org.springframework.data.elasticsearch.core.SearchHits<PaymentRecordDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(PaymentRecordDocument::toEntity)
                .collect(Collectors.toList());
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void publishPaymentStatusChanged(PaymentRecord record) {
        if (record == null || isBlank(record.getPaymentStatus())) {
            return;
        }
        applicationEventPublisher.publishEvent(new PaymentStatusChangedEvent(
                firstNonBlank(record.getCreatedBy(), record.getUpdatedBy(), record.getPayerContact()),
                record.getPaymentId(),
                record.getFineId(),
                record.getPaymentStatus(),
                record.getUpdatedAt()
        ));
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (!isBlank(value)) {
                return value;
            }
        }
        return null;
    }
}
