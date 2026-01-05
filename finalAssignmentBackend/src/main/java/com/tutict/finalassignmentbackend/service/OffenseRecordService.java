package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.statemachine.states.OffenseProcessState;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseRecordDocument;
import com.tutict.finalassignmentbackend.mapper.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
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
public class OffenseRecordService {

    private static final Logger log = Logger.getLogger(OffenseRecordService.class.getName());
    private static final String CACHE_NAME = "offenseRecordCache";

    private final OffenseRecordMapper offenseRecordMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final OffenseInformationSearchRepository offenseInformationSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public OffenseRecordService(OffenseRecordMapper offenseRecordMapper,
                                SysRequestHistoryMapper sysRequestHistoryMapper,
                                OffenseInformationSearchRepository offenseInformationSearchRepository,
                                KafkaTemplate<String, String> kafkaTemplate,
                                ObjectMapper objectMapper) {
        this.offenseRecordMapper = offenseRecordMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.offenseInformationSearchRepository = offenseInformationSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "OffenseRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseRecord offenseRecord, String action) {
        Objects.requireNonNull(offenseRecord, "OffenseRecord must not be null");
        if (sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey) != null) {
            throw new RuntimeException("Duplicate offense record request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("offense_record_" + action, idempotencyKey, offenseRecord);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(offenseRecord.getOffenseId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public OffenseRecord createOffenseRecord(OffenseRecord offenseRecord) {
        validateOffenseRecord(offenseRecord);
        // 同步写库，成功后再异步刷新 ES
        offenseRecordMapper.insert(offenseRecord);
        syncToIndexAfterCommit(offenseRecord);
        return offenseRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public OffenseRecord updateOffenseRecord(OffenseRecord offenseRecord) {
        validateOffenseRecord(offenseRecord);
        requirePositive(offenseRecord.getOffenseId(), "Offense ID");
        int rows = offenseRecordMapper.updateById(offenseRecord);
        if (rows == 0) {
            throw new IllegalStateException("No OffenseRecord updated for id=" + offenseRecord.getOffenseId());
        }
        syncToIndexAfterCommit(offenseRecord);
        return offenseRecord;
    }

    public OffenseRecord updateProcessStatus(Long offenseId, OffenseProcessState newState) {
        requirePositive(offenseId, "Offense ID");
        OffenseRecord existing = offenseRecordMapper.selectById(offenseId);
        if (existing == null) {
            throw new IllegalStateException("OffenseRecord not found for id=" + offenseId);
        }
        // 仅允许状态机计算出的状态覆盖数据库的 process_status 字段
        existing.setProcessStatus(newState != null ? newState.getCode() : existing.getProcessStatus());
        existing.setUpdatedAt(LocalDateTime.now());
        offenseRecordMapper.updateById(existing);
        syncToIndexAfterCommit(existing);
        return existing;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteOffenseRecord(Long offenseId) {
        requirePositive(offenseId, "Offense ID");
        int rows = offenseRecordMapper.deleteById(offenseId);
        if (rows == 0) {
            throw new IllegalStateException("No OffenseRecord deleted for id=" + offenseId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                offenseInformationSearchRepository.deleteById(offenseId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#offenseId", unless = "#result == null")
    public OffenseRecord findById(Long offenseId) {
        requirePositive(offenseId, "Offense ID");
        return offenseInformationSearchRepository.findById(offenseId)
                .map(OffenseRecordDocument::toEntity)
                .orElseGet(() -> {
                    OffenseRecord entity = offenseRecordMapper.selectById(offenseId);
                    if (entity != null) {
                        offenseInformationSearchRepository.save(OffenseRecordDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> findAll() {
        List<OffenseRecord> fromIndex = StreamSupport.stream(offenseInformationSearchRepository.findAll().spliterator(), false)
                .map(OffenseRecordDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<OffenseRecord> fromDb = offenseRecordMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'driver:' + #driverId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> findByDriverId(Long driverId, int page, int size) {
        requirePositive(driverId, "Driver ID");
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.findByDriverId(driverId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'vehicle:' + #vehicleId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> findByVehicleId(Long vehicleId, int page, int size) {
        requirePositive(vehicleId, "Vehicle ID");
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.findByVehicleId(vehicleId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("vehicle_id", vehicleId)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'code:' + #offenseCode + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByOffenseCode(String offenseCode, int page, int size) {
        if (isBlank(offenseCode)) {
            return List.of();
        }
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByOffenseCode(offenseCode, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.like("offense_code", offenseCode)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #processStatus + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByProcessStatus(String processStatus, int page, int size) {
        if (isBlank(processStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByProcessStatus(processStatus, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("process_status", processStatus)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'timeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByOffenseTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByOffenseTimeRange(startTime, endTime, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.between("offense_time", start, end)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'number:' + #offenseNumber + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByOffenseNumber(String offenseNumber, int page, int size) {
        if (isBlank(offenseNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByOffenseNumber(offenseNumber, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.like("offense_number", offenseNumber)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'location:' + #offenseLocation + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByOffenseLocation(String offenseLocation, int page, int size) {
        if (isBlank(offenseLocation)) {
            return List.of();
        }
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByOffenseLocation(offenseLocation, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.like("offense_location", offenseLocation)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'province:' + #offenseProvince + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByOffenseProvince(String offenseProvince, int page, int size) {
        if (isBlank(offenseProvince)) {
            return List.of();
        }
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByOffenseProvince(offenseProvince, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_province", offenseProvince)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'city:' + #offenseCity + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByOffenseCity(String offenseCity, int page, int size) {
        if (isBlank(offenseCity)) {
            return List.of();
        }
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByOffenseCity(offenseCity, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_city", offenseCity)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'notification:' + #notificationStatus + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByNotificationStatus(String notificationStatus, int page, int size) {
        if (isBlank(notificationStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByNotificationStatus(notificationStatus, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("notification_status", notificationStatus)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'agency:' + #enforcementAgency + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByEnforcementAgency(String enforcementAgency, int page, int size) {
        if (isBlank(enforcementAgency)) {
            return List.of();
        }
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByEnforcementAgency(enforcementAgency, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.like("enforcement_agency", enforcementAgency)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'fineRange:' + #minAmount + ':' + #maxAmount + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> searchByFineAmountRange(double minAmount, double maxAmount, int page, int size) {
        validatePagination(page, size);
        if (minAmount > maxAmount) {
            return List.of();
        }
        List<OffenseRecord> index = mapHits(offenseInformationSearchRepository.searchByFineAmountRange(minAmount, maxAmount, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
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

    private void sendKafkaMessage(String topic, String idempotencyKey, OffenseRecord offenseRecord) {
        try {
            String payload = objectMapper.writeValueAsString(offenseRecord);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send OffenseRecord Kafka message", ex);
            throw new RuntimeException("Failed to send OffenseRecord event", ex);
        }
    }

    private void syncToIndexAfterCommit(OffenseRecord offenseRecord) {
        if (offenseRecord == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                OffenseRecordDocument doc = OffenseRecordDocument.fromEntity(offenseRecord);
                if (doc != null) {
                    offenseInformationSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<OffenseRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<OffenseRecordDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(OffenseRecordDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    offenseInformationSearchRepository.saveAll(documents);
                }
            }
        });
    }

    /**
     * 将 ES 命中结果转换成实体列表，供缓存 miss 时快速返回
     */
    private List<OffenseRecord> mapHits(org.springframework.data.elasticsearch.core.SearchHits<OffenseRecordDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(OffenseRecordDocument::toEntity)
                .collect(Collectors.toList());
    }

    private List<OffenseRecord> fetchFromDatabase(QueryWrapper<OffenseRecord> wrapper, int page, int size) {
        Page<OffenseRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        offenseRecordMapper.selectPage(mpPage, wrapper);
        List<OffenseRecord> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validateOffenseRecord(OffenseRecord offenseRecord) {
        Objects.requireNonNull(offenseRecord, "OffenseRecord must not be null");
        if (offenseRecord.getOffenseTime() == null) {
            offenseRecord.setOffenseTime(LocalDateTime.now());
        }
        if (offenseRecord.getProcessStatus() == null || offenseRecord.getProcessStatus().isBlank()) {
            offenseRecord.setProcessStatus("Pending");
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
