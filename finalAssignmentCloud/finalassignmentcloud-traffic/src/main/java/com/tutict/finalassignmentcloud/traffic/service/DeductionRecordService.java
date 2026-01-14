package com.tutict.finalassignmentcloud.traffic.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.DeductionRecord;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.entity.elastic.DeductionRecordDocument;
import com.tutict.finalassignmentcloud.traffic.mapper.DeductionRecordMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.traffic.repository.DeductionRecordSearchRepository;
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
public class DeductionRecordService {

    private static final Logger log = Logger.getLogger(DeductionRecordService.class.getName());
    private static final String CACHE_NAME = "deductionRecordCache";

    private final DeductionRecordMapper deductionRecordMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final DeductionRecordSearchRepository deductionRecordSearchRepository;
    private final KafkaTemplate<String, DeductionRecord> kafkaTemplate;

    @Autowired
    public DeductionRecordService(DeductionRecordMapper deductionRecordMapper,
                                  SysRequestHistoryMapper sysRequestHistoryMapper,
                                  DeductionRecordSearchRepository deductionRecordSearchRepository,
                                  KafkaTemplate<String, DeductionRecord> kafkaTemplate) {
        this.deductionRecordMapper = deductionRecordMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.deductionRecordSearchRepository = deductionRecordSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "DeductionRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DeductionRecord deductionRecord, String action) {
        Objects.requireNonNull(deductionRecord, "DeductionRecord must not be null");
        if (sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey) != null) {
            throw new RuntimeException("Duplicate deduction record request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("deduction_record_" + action, idempotencyKey, deductionRecord);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(deductionRecord.getDeductionId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public DeductionRecord createDeductionRecord(DeductionRecord deductionRecord) {
        validateDeductionRecord(deductionRecord);
        deductionRecordMapper.insert(deductionRecord);
        syncToIndexAfterCommit(deductionRecord);
        return deductionRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public DeductionRecord updateDeductionRecord(DeductionRecord deductionRecord) {
        validateDeductionRecord(deductionRecord);
        requirePositive(deductionRecord.getDeductionId(), "Deduction ID");
        int rows = deductionRecordMapper.updateById(deductionRecord);
        if (rows == 0) {
            throw new IllegalStateException("No DeductionRecord updated for id=" + deductionRecord.getDeductionId());
        }
        syncToIndexAfterCommit(deductionRecord);
        return deductionRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteDeductionRecord(Long deductionId) {
        requirePositive(deductionId, "Deduction ID");
        int rows = deductionRecordMapper.deleteById(deductionId);
        if (rows == 0) {
            throw new IllegalStateException("No DeductionRecord deleted for id=" + deductionId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                deductionRecordSearchRepository.deleteById(deductionId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#deductionId", unless = "#result == null")
    public DeductionRecord findById(Long deductionId) {
        requirePositive(deductionId, "Deduction ID");
        return deductionRecordSearchRepository.findById(deductionId)
                .map(DeductionRecordDocument::toEntity)
                .orElseGet(() -> {
                    DeductionRecord entity = deductionRecordMapper.selectById(deductionId);
                    if (entity != null) {
                        deductionRecordSearchRepository.save(DeductionRecordDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<DeductionRecord> findAll() {
        List<DeductionRecord> fromIndex = StreamSupport.stream(deductionRecordSearchRepository.findAll().spliterator(), false)
                .map(DeductionRecordDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<DeductionRecord> fromDb = deductionRecordMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'driver:' + #driverId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DeductionRecord> findByDriverId(Long driverId, int page, int size) {
        requirePositive(driverId, "Driver ID");
        validatePagination(page, size);
        List<DeductionRecord> index = mapHits(deductionRecordSearchRepository.findByDriverId(driverId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'offense:' + #offenseId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DeductionRecord> findByOffenseId(Long offenseId, int page, int size) {
        requirePositive(offenseId, "Offense ID");
        validatePagination(page, size);
        List<DeductionRecord> index = mapHits(deductionRecordSearchRepository.findByOffenseId(offenseId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_id", offenseId)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'handlerPrefix:' + #handler + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DeductionRecord> searchByHandlerPrefix(String handler, int page, int size) {
        if (isBlank(handler)) {
            return List.of();
        }
        validatePagination(page, size);
        List<DeductionRecord> index = mapHits(deductionRecordSearchRepository.searchByHandlerPrefix(handler, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("handler", handler);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'handlerFuzzy:' + #handler + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DeductionRecord> searchByHandlerFuzzy(String handler, int page, int size) {
        if (isBlank(handler)) {
            return List.of();
        }
        validatePagination(page, size);
        List<DeductionRecord> index = mapHits(deductionRecordSearchRepository.searchByHandlerFuzzy(handler, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.like("handler", handler);
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #status + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DeductionRecord> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        List<DeductionRecord> index = mapHits(deductionRecordSearchRepository.searchByStatus(status, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'timeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DeductionRecord> searchByDeductionTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        List<DeductionRecord> index = mapHits(deductionRecordSearchRepository.searchByDeductionTimeRange(startTime, endTime, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
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

    private void syncToIndexAfterCommit(DeductionRecord deductionRecord) {
        if (deductionRecord == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                DeductionRecordDocument doc = DeductionRecordDocument.fromEntity(deductionRecord);
                if (doc != null) {
                    deductionRecordSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<DeductionRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<DeductionRecordDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(DeductionRecordDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    deductionRecordSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, DeductionRecord deductionRecord) {
        try {
            kafkaTemplate.send(topic, idempotencyKey, deductionRecord);
        } catch (Exception ex) {
            log.log(Level.SEVERE,
                    String.format("Failed to send DeductionRecord Kafka message (topic=%s, key=%s)", topic, idempotencyKey),
                    ex);
            throw new RuntimeException("Failed to send deduction record event", ex);
        }
    }

    private List<DeductionRecord> mapHits(org.springframework.data.elasticsearch.core.SearchHits<DeductionRecordDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(DeductionRecordDocument::toEntity)
                .collect(Collectors.toList());
    }

    private List<DeductionRecord> fetchFromDatabase(QueryWrapper<DeductionRecord> wrapper, int page, int size) {
        Page<DeductionRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        deductionRecordMapper.selectPage(mpPage, wrapper);
        List<DeductionRecord> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validateDeductionRecord(DeductionRecord deductionRecord) {
        Objects.requireNonNull(deductionRecord, "DeductionRecord must not be null");
        if (deductionRecord.getDeductionTime() == null) {
            deductionRecord.setDeductionTime(LocalDateTime.now());
        }
        if (deductionRecord.getStatus() == null || deductionRecord.getStatus().isBlank()) {
            deductionRecord.setStatus("Pending");
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
}

