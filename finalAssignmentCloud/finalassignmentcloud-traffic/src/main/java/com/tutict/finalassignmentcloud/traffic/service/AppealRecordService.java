package com.tutict.finalassignmentcloud.traffic.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.traffic.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.AppealRecord;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.entity.elastic.AppealRecordDocument;
import com.tutict.finalassignmentcloud.traffic.mapper.AppealRecordMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.traffic.repository.AppealRecordSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.SearchHits;
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

@Service
public class AppealRecordService {

    private static final Logger log = Logger.getLogger(AppealRecordService.class.getName());
    private static final String CACHE = "appealRecordCache";

    private final AppealRecordMapper appealRecordMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final AppealRecordSearchRepository appealRecordSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public AppealRecordService(AppealRecordMapper appealRecordMapper,
                               SysRequestHistoryMapper sysRequestHistoryMapper,
                               KafkaTemplate<String, String> kafkaTemplate,
                               AppealRecordSearchRepository appealRecordSearchRepository,
                               ObjectMapper objectMapper) {
        this.appealRecordMapper = appealRecordMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.appealRecordSearchRepository = appealRecordSearchRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    @WsAction(service = "AppealRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        Objects.requireNonNull(appealRecord, "Appeal record cannot be null");
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate appeal request detected");
        }

        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        sendKafkaMessage("appeal_" + action, idempotencyKey, appealRecord);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(appealRecord.getAppealId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        validateAppeal(appealRecord);
        appealRecordMapper.insert(appealRecord);
        syncIndexAfterCommit(appealRecord);
        return appealRecord;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        validateAppealId(appealRecord);
        int rows = appealRecordMapper.updateById(appealRecord);
        if (rows == 0) {
            throw new IllegalStateException("Appeal not found: " + appealRecord.getAppealId());
        }
        syncIndexAfterCommit(appealRecord);
        return appealRecord;
    }

    /**
     * 供工作流调用的状态更新方法，只改 processStatus 字段
     */
    public AppealRecord updateProcessStatus(Long appealId, AppealProcessState newState) {
        validateAppealId(appealId);
        AppealRecord existing = appealRecordMapper.selectById(appealId);
        if (existing == null) {
            throw new IllegalStateException("Appeal not found: " + appealId);
        }
        existing.setProcessStatus(newState != null ? newState.getCode() : existing.getProcessStatus());
        existing.setUpdatedAt(LocalDateTime.now());
        appealRecordMapper.updateById(existing);
        syncIndexAfterCommit(existing);
        return existing;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public void deleteAppeal(Long appealId) {
        validateAppealId(appealId);
        int rows = appealRecordMapper.deleteById(appealId);
        if (rows == 0) {
            throw new IllegalStateException("Appeal not found: " + appealId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                appealRecordSearchRepository.deleteById(appealId);
            }
        });
    }

    @Cacheable(cacheNames = CACHE, key = "#appealId", unless = "#result == null")
    public AppealRecord getAppealById(Long appealId) {
        validateAppealId(appealId);
        return appealRecordSearchRepository.findById(appealId)
                .map(AppealRecordDocument::toEntity)
                .orElseGet(() -> {
                    AppealRecord entity = appealRecordMapper.selectById(appealId);
                    if (entity != null) {
                        appealRecordSearchRepository.save(AppealRecordDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Cacheable(cacheNames = CACHE, key = "'offense:' + #offenseId", unless = "#result.isEmpty()")
    public List<AppealRecord> findByOffenseId(Long offenseId, int page, int size) {
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.findByOffenseId(offenseId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("offense_id", offenseId)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealNumberPrefix:' + #appealNumber + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppealNumberPrefix(String appealNumber, int page, int size) {
        if (isBlank(appealNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByAppealNumberPrefix(appealNumber, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appeal_number", appealNumber)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealNumberFuzzy:' + #appealNumber + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppealNumberFuzzy(String appealNumber, int page, int size) {
        if (isBlank(appealNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByAppealNumberFuzzy(appealNumber, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.like("appeal_number", appealNumber)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantNamePrefix:' + #appellantName + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppellantNamePrefix(String appellantName, int page, int size) {
        if (isBlank(appellantName)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByAppellantNamePrefix(appellantName, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appellant_name", appellantName)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantNameFuzzy:' + #appellantName + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppellantNameFuzzy(String appellantName, int page, int size) {
        if (isBlank(appellantName)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByAppellantNameFuzzy(appellantName, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.like("appellant_name", appellantName)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appellantIdCard:' + #appellantIdCard + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppellantIdCard(String appellantIdCard, int page, int size) {
        if (isBlank(appellantIdCard)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByAppellantIdCard(appellantIdCard, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("appellant_id_card", appellantIdCard)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'acceptanceStatus:' + #acceptanceStatus + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAcceptanceStatus(String acceptanceStatus, int page, int size) {
        if (isBlank(acceptanceStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByAcceptanceStatus(acceptanceStatus, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("acceptance_status", acceptanceStatus)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'processStatus:' + #processStatus + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByProcessStatus(String processStatus, int page, int size) {
        if (isBlank(processStatus)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByProcessStatus(processStatus, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.eq("process_status", processStatus)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'appealTimeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAppealTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByAppealTimeRange(startTime, endTime, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.between("appeal_time", start, end)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE, key = "'acceptanceHandler:' + #acceptanceHandler + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, int page, int size) {
        if (isBlank(acceptanceHandler)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AppealRecord> index = mapHits(appealRecordSearchRepository.searchByAcceptanceHandler(acceptanceHandler, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<>();
        wrapper.likeRight("acceptance_handler", acceptanceHandler)
                .orderByDesc("appeal_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
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

    private void sendKafkaMessage(String topic, String idempotencyKey, AppealRecord appealRecord) {
        try {
            String payload = objectMapper.writeValueAsString(appealRecord);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception e) {
            log.log(Level.WARNING, "Failed to send appeal Kafka message", e);
            throw new RuntimeException("Failed to send appeal record event", e);
        }
    }

    private void syncIndexAfterCommit(AppealRecord appealRecord) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                AppealRecordDocument doc = AppealRecordDocument.fromEntity(appealRecord);
                if (doc != null) {
                    appealRecordSearchRepository.save(doc);
                }
            }
        });
    }

    private List<AppealRecord> fetchFromDatabase(QueryWrapper<AppealRecord> wrapper, int page, int size) {
        Page<AppealRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        appealRecordMapper.selectPage(mpPage, wrapper);
        List<AppealRecord> records = mpPage.getRecords();
        records.stream()
                .map(AppealRecordDocument::fromEntity)
                .filter(Objects::nonNull)
                .forEach(appealRecordSearchRepository::save);
        return records;
    }

    private List<AppealRecord> mapHits(SearchHits<AppealRecordDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(SearchHit::getContent)
                .map(AppealRecordDocument::toEntity)
                .collect(Collectors.toList());
    }

    private Pageable pageable(int page, int size) {
        return PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
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

