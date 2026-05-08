package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.appeal.application.AppealRecordApplicationService;
import com.tutict.finalassignmentbackend.appeal.domain.AppealRecordDomainService;
import com.tutict.finalassignmentbackend.appeal.infrastructure.search.AppealRecordSearchIndexer;
import com.tutict.finalassignmentbackend.config.statemachine.states.AppealProcessState;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import com.tutict.finalassignmentbackend.mapper.AppealRecordMapper;
import com.tutict.finalassignmentbackend.repository.AppealRecordSearchRepository;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class AppealRecordService {

    private static final Logger log = Logger.getLogger(AppealRecordService.class.getName());
    private static final String CACHE = "appealRecordCache";

    private final AppealRecordApplicationService applicationService;
    private final AppealRecordMapper appealRecordMapper;
    private final AppealRecordSearchRepository appealRecordSearchRepository;
    private final AppealRecordDomainService domainService;
    private final AppealRecordSearchIndexer searchIndexer;

    public AppealRecordService(
            AppealRecordApplicationService applicationService,
            AppealRecordMapper appealRecordMapper,
            AppealRecordSearchRepository appealRecordSearchRepository,
            AppealRecordDomainService domainService,
            AppealRecordSearchIndexer searchIndexer
    ) {
        this.applicationService = applicationService;
        this.appealRecordMapper = appealRecordMapper;
        this.appealRecordSearchRepository = appealRecordSearchRepository;
        this.domainService = domainService;
        this.searchIndexer = searchIndexer;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    @WsAction(service = "AppealRecordService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealRecord appealRecord, String action) {
        applicationService.checkAndInsertIdempotency(idempotencyKey, appealRecord, action);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public AppealRecord createAppeal(AppealRecord appealRecord) {
        return applicationService.createAppeal(appealRecord);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public AppealRecord updateAppeal(AppealRecord appealRecord) {
        return applicationService.updateAppeal(appealRecord);
    }

    /**
     * 供工作流调用的状态更新方法，只改 processStatus 字段
     */
    public AppealRecord updateProcessStatus(Long appealId, AppealProcessState newState) {
        return applicationService.updateProcessStatus(appealId, newState);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE, allEntries = true)
    public void deleteAppeal(Long appealId) {
        applicationService.deleteAppeal(appealId);
    }

    @Cacheable(cacheNames = CACHE, key = "#appealId", unless = "#result == null")
    public AppealRecord getAppealById(Long appealId) {
        domainService.validateAppealId(appealId);
        return appealRecordSearchRepository.findById(appealId)
                .map(AppealRecordDocument::toEntity)
                .orElseGet(() -> {
                    AppealRecord entity = appealRecordMapper.selectById(appealId);
                    if (entity != null) {
                        searchIndexer.index(entity);
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

    public boolean shouldSkipProcessing(String idempotencyKey) {
        return applicationService.shouldSkipProcessing(idempotencyKey);
    }

    public void markHistorySuccess(String idempotencyKey, Long appealId) {
        applicationService.markHistorySuccess(idempotencyKey, appealId);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        applicationService.markHistoryFailure(idempotencyKey, reason);
    }

    private List<AppealRecord> fetchFromDatabase(QueryWrapper<AppealRecord> wrapper, int page, int size) {
        Page<AppealRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        appealRecordMapper.selectPage(mpPage, wrapper);
        List<AppealRecord> records = mpPage.getRecords();
        searchIndexer.indexAll(records);
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
}
