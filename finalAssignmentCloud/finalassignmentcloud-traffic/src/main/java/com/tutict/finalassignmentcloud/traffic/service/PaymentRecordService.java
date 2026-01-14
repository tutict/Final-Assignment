package com.tutict.finalassignmentcloud.traffic.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.PaymentState;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.PaymentRecord;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.entity.elastic.PaymentRecordDocument;
import com.tutict.finalassignmentcloud.traffic.mapper.PaymentRecordMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.traffic.repository.PaymentRecordSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
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
public class PaymentRecordService {

    private static final Logger log = Logger.getLogger(PaymentRecordService.class.getName());
    private static final String CACHE_NAME = "paymentRecordCache";

    private final PaymentRecordMapper paymentRecordMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final PaymentRecordSearchRepository paymentRecordSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public PaymentRecordService(PaymentRecordMapper paymentRecordMapper,
                                SysRequestHistoryMapper sysRequestHistoryMapper,
                                PaymentRecordSearchRepository paymentRecordSearchRepository,
                                KafkaTemplate<String, String> kafkaTemplate,
                                ObjectMapper objectMapper) {
        this.paymentRecordMapper = paymentRecordMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.paymentRecordSearchRepository = paymentRecordSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "PaymentRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, PaymentRecord paymentRecord, String action) {
        Objects.requireNonNull(paymentRecord, "PaymentRecord must not be null");
        if (sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey) != null) {
            throw new RuntimeException("Duplicate payment record request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        // 利用 Kafka 广播支付事件结果，以便审计和对账
        sendKafkaMessage("payment_record_" + action, idempotencyKey, paymentRecord);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(paymentRecord.getPaymentId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public PaymentRecord createPaymentRecord(PaymentRecord paymentRecord) {
        validatePaymentRecord(paymentRecord);
        paymentRecordMapper.insert(paymentRecord);
        syncToIndexAfterCommit(paymentRecord);
        return paymentRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public PaymentRecord updatePaymentRecord(PaymentRecord paymentRecord) {
        validatePaymentRecord(paymentRecord);
        requirePositive(paymentRecord.getPaymentId(), "Payment ID");
        int rows = paymentRecordMapper.updateById(paymentRecord);
        if (rows == 0) {
            throw new IllegalStateException("No PaymentRecord updated for id=" + paymentRecord.getPaymentId());
        }
        syncToIndexAfterCommit(paymentRecord);
        return paymentRecord;
    }

    public PaymentRecord updatePaymentStatus(Long paymentId, PaymentState newState) {
        requirePositive(paymentId, "Payment ID");
        PaymentRecord existing = paymentRecordMapper.selectById(paymentId);
        if (existing == null) {
            throw new IllegalStateException("PaymentRecord not found for id=" + paymentId);
        }
        // 工作流只允许更新状态枚举值，其他字段由业务接口维护
        existing.setPaymentStatus(newState != null ? newState.getCode() : existing.getPaymentStatus());
        existing.setUpdatedAt(LocalDateTime.now());
        paymentRecordMapper.updateById(existing);
        syncToIndexAfterCommit(existing);
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
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                paymentRecordSearchRepository.deleteById(paymentId);
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

    // 通过事务回调，确保只有数据库提交成功后才刷新 ES，避免脏数据
    private void syncToIndexAfterCommit(PaymentRecord paymentRecord) {
        if (paymentRecord == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                PaymentRecordDocument doc = PaymentRecordDocument.fromEntity(paymentRecord);
                if (doc != null) {
                    paymentRecordSearchRepository.save(doc);
                }
            }
        });
    }

    private List<PaymentRecord> fetchFromDatabase(QueryWrapper<PaymentRecord> wrapper, int page, int size) {
        Page<PaymentRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        paymentRecordMapper.selectPage(mpPage, wrapper);
        List<PaymentRecord> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, PaymentRecord paymentRecord) {
        try {
            String payload = objectMapper.writeValueAsString(paymentRecord);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send PaymentRecord Kafka message", ex);
            throw new RuntimeException("Failed to send PaymentRecord event", ex);
        }
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

    // 批量操作时同样复用 afterCommit 钩子，降低对 ES 的写入频率
    private void syncBatchToIndexAfterCommit(List<PaymentRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<PaymentRecordDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(PaymentRecordDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    paymentRecordSearchRepository.saveAll(documents);
                }
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
}

