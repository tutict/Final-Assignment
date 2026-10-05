package com.tutict.finalassignmentbackend.service.offense;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.offense.FineRecord;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.FineRecordDocument;
import com.tutict.finalassignmentbackend.mapper.offense.FineRecordMapper;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.reliability.IdempotencyConflictException;
import com.tutict.finalassignmentbackend.reliability.IdempotencyInProgressException;
import com.tutict.finalassignmentbackend.reliability.IdempotencyReplayException;
import com.tutict.finalassignmentbackend.reliability.LedgerBodyFingerprint;
import com.tutict.finalassignmentbackend.reliability.LedgerHistoryReserve;
import com.tutict.finalassignmentbackend.repository.FineRecordSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class FineRecordService {

    private static final Logger log = Logger.getLogger(FineRecordService.class.getName());
    private static final String CACHE_NAME = "fineRecordCache";

    private final FineRecordMapper fineRecordMapper;
    private final OffenseRecordMapper offenseRecordMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final FineRecordSearchRepository fineRecordSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;
    private final LedgerHistoryReserve ledgerHistoryReserve;

    @Autowired
    public FineRecordService(FineRecordMapper fineRecordMapper,
                             OffenseRecordMapper offenseRecordMapper,
                             SysRequestHistoryMapper sysRequestHistoryMapper,
                             FineRecordSearchRepository fineRecordSearchRepository,
                             KafkaTemplate<String, String> kafkaTemplate,
                             ObjectMapper objectMapper,
                             LedgerHistoryReserve ledgerHistoryReserve) {
        this.fineRecordMapper = fineRecordMapper;
        this.offenseRecordMapper = offenseRecordMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.fineRecordSearchRepository = fineRecordSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
        this.ledgerHistoryReserve = ledgerHistoryReserve;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "FineRecordService", action = "checkAndInsertIdempotency", roles = {"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE"})
    public void checkAndInsertIdempotency(String idempotencyKey, FineRecord fineRecord, String action) {
        Objects.requireNonNull(fineRecord, "FineRecord must not be null");
        String fingerprint = LedgerBodyFingerprint.sha256(String.join("|",
                String.valueOf(fineRecord.getOffenseId()),
                String.valueOf(fineRecord.getFineAmount()),
                String.valueOf(fineRecord.getFineNumber())));
        ledgerHistoryReserve.reserve(idempotencyKey, "FINE_" + action, "POST", "/api/fines", fingerprint);
        try {
            sendKafkaMessage("fine_record_" + action, idempotencyKey, fineRecord);
        } catch (RuntimeException ex) {
            log.log(Level.WARNING, "Fine Kafka publish failed after idempotency reserve", ex);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public FineRecord createFineRecord(FineRecord fineRecord) {
        validateFineRecord(fineRecord);
        fineRecordMapper.insert(fineRecord);
        syncToIndexAfterCommit(fineRecord);
        return fineRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public FineRecord updateFineRecord(FineRecord fineRecord) {
        validateFineRecord(fineRecord);
        requirePositive(fineRecord.getFineId(), "Fine ID");
        int rows = fineRecordMapper.updateById(fineRecord);
        if (rows == 0) {
            throw new IllegalStateException("No FineRecord updated for id=" + fineRecord.getFineId());
        }
        syncToIndexAfterCommit(fineRecord);
        return fineRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteFineRecord(Long fineId) {
        requirePositive(fineId, "Fine ID");
        int rows = fineRecordMapper.deleteById(fineId);
        if (rows == 0) {
            throw new IllegalStateException("No FineRecord deleted for id=" + fineId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                fineRecordSearchRepository.deleteById(fineId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#fineId", unless = "#result == null")
    public FineRecord findById(Long fineId) {
        requirePositive(fineId, "Fine ID");
        return fineRecordSearchRepository.findById(fineId)
                .map(FineRecordDocument::toEntity)
                .orElseGet(() -> {
                    FineRecord entity = fineRecordMapper.selectById(fineId);
                    if (entity != null) {
                        fineRecordSearchRepository.save(FineRecordDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<FineRecord> findAll() {
        List<FineRecord> fromIndex = StreamSupport.stream(fineRecordSearchRepository.findAll().spliterator(), false)
                .map(FineRecordDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<FineRecord> fromDb = fineRecordMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'offense:' + #offenseId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<FineRecord> findByOffenseId(Long offenseId, int page, int size) {
        requirePositive(offenseId, "Offense ID");
        validatePagination(page, size);
        List<FineRecord> index = mapHits(fineRecordSearchRepository.findByOffenseId(offenseId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_id", offenseId)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'driver:' + #driverId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<FineRecord> findByDriverId(Long driverId, int page, int size) {
        requirePositive(driverId, "Driver ID");
        validatePagination(page, size);
        List<FineRecord> index = mapHits(fineRecordSearchRepository.findByDriverId(driverId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'handlerPrefix:' + #handler + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<FineRecord> searchByHandlerPrefix(String handler, int page, int size) {
        if (isBlank(handler)) {
            return List.of();
        }
        validatePagination(page, size);
        List<FineRecord> index = mapHits(fineRecordSearchRepository.searchByHandlerPrefix(handler, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("handler", handler)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'handlerFuzzy:' + #handler + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<FineRecord> searchByHandlerFuzzy(String handler, int page, int size) {
        if (isBlank(handler)) {
            return List.of();
        }
        validatePagination(page, size);
        List<FineRecord> index = mapHits(fineRecordSearchRepository.searchByHandlerFuzzy(handler, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.like("handler", handler)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #paymentStatus + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<FineRecord> searchByPaymentStatus(String paymentStatus, int page, int size) {
        if (isBlank(paymentStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        List<FineRecord> index = mapHits(fineRecordSearchRepository.searchByPaymentStatus(paymentStatus, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("payment_status", paymentStatus)
                .orderByDesc("fine_date");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'dateRange:' + #startDate + ':' + #endDate + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<FineRecord> searchByFineDateRange(String startDate, String endDate, int page, int size) {
        validatePagination(page, size);
        LocalDate start = parseDate(startDate, "startDate");
        LocalDate end = parseDate(endDate, "endDate");
        if (start == null || end == null) {
            return List.of();
        }
        List<FineRecord> index = mapHits(fineRecordSearchRepository.searchByFineDateRange(startDate, endDate, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
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
        if (history.getRequestParams() == null || !history.getRequestParams().startsWith("sha256:")) {
            history.setRequestParams("DONE");
        }
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        if ("SUCCESS".equalsIgnoreCase(history.getBusinessStatus())) {
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, FineRecord fineRecord) {
        try {
            String payload = objectMapper.writeValueAsString(fineRecord);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send FineRecord Kafka message", ex);
            throw new RuntimeException("Failed to send FineRecord event", ex);
        }
    }

    private void syncToIndexAfterCommit(FineRecord fineRecord) {
        if (fineRecord == null) {
            return;
        }
        runAfterCommitOrNow(() -> {
            FineRecordDocument doc = FineRecordDocument.fromEntity(fineRecord);
            if (doc != null) {
                fineRecordSearchRepository.save(doc);
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<FineRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        runAfterCommitOrNow(() -> {
            List<FineRecordDocument> documents = records.stream()
                    .filter(Objects::nonNull)
                    .map(FineRecordDocument::fromEntity)
                    .filter(Objects::nonNull)
                    .collect(Collectors.toList());
            if (!documents.isEmpty()) {
                fineRecordSearchRepository.saveAll(documents);
            }
        });
    }

    private void runAfterCommitOrNow(Runnable action) {
        Runnable safe = () -> {
            try {
                action.run();
            } catch (RuntimeException ex) {
                log.log(Level.WARNING, "Fine index sync failed", ex);
            }
        };
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            safe.run();
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                safe.run();
            }
        });
    }

    private List<FineRecord> mapHits(org.springframework.data.elasticsearch.core.SearchHits<FineRecordDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(FineRecordDocument::toEntity)
                .collect(Collectors.toList());
    }

    private List<FineRecord> fetchFromDatabase(QueryWrapper<FineRecord> wrapper, int page, int size) {
        Page<FineRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        fineRecordMapper.selectPage(mpPage, wrapper);
        List<FineRecord> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validateFineRecord(FineRecord fineRecord) {
        Objects.requireNonNull(fineRecord, "FineRecord must not be null");
        if (fineRecord.getFineDate() == null) {
            LocalDate parsed = parseFineTime(fineRecord.getFineTime());
            fineRecord.setFineDate(parsed != null ? parsed : LocalDate.now());
        }
        if (fineRecord.getFineNumber() == null || fineRecord.getFineNumber().isBlank()) {
            fineRecord.setFineNumber("FN" + System.currentTimeMillis());
        }
        if (fineRecord.getIssuingAuthority() == null || fineRecord.getIssuingAuthority().isBlank()) {
            fineRecord.setIssuingAuthority("未填写");
        }
        if (fineRecord.getHandler() == null || fineRecord.getHandler().isBlank()) {
            fineRecord.setHandler("系统");
        }
        if (fineRecord.getTotalAmount() == null) {
            fineRecord.setTotalAmount(fineRecord.getFineAmount());
        }
        if (fineRecord.getPaymentStatus() == null || fineRecord.getPaymentStatus().isBlank()) {
            fineRecord.setPaymentStatus("Unpaid");
        }
        if (fineRecord.getOffenseId() == null || fineRecord.getOffenseId() <= 0) {
            throw new IllegalArgumentException("请选择关联的违法记录");
        }
        if (fineRecord.getOffenseId() != null) {
            OffenseRecord linkedOffense = offenseRecordMapper.selectById(fineRecord.getOffenseId());
            if (linkedOffense == null) {
                throw new IllegalArgumentException("违法记录不存在");
            }
            if (fineRecord.getDriverId() == null) {
                fineRecord.setDriverId(linkedOffense.getDriverId());
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

    private LocalDate parseFineTime(String value) {
        if (isBlank(value)) {
            return null;
        }
        String text = value.trim();
        if (text.length() >= 10) {
            text = text.substring(0, 10);
        }
        try {
            return LocalDate.parse(text);
        } catch (DateTimeParseException ex) {
            log.log(Level.WARNING, "Failed to parse fineTime: " + value, ex);
            return null;
        }
    }

    private LocalDate parseDate(String value, String fieldName) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDate.parse(value);
        } catch (DateTimeParseException ex) {
            Logger.getLogger(FineRecordService.class.getName())
                    .log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
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
}
