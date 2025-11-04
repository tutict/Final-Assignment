package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.entity.DeductionRecord;
import com.tutict.finalassignmentbackend.entity.elastic.DeductionRecordDocument;
import com.tutict.finalassignmentbackend.mapper.DeductionRecordMapper;
import com.tutict.finalassignmentbackend.repository.DeductionRecordSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;

@Service
public class DeductionRecordService extends AbstractElasticsearchCrudService<DeductionRecord, DeductionRecordDocument, Long> {

    private static final String CACHE_NAME = "deductionRecordCache";

    private final DeductionRecordSearchRepository repository;

    @Autowired
    public DeductionRecordService(DeductionRecordMapper mapper,
                                  DeductionRecordSearchRepository repository) {
        super(mapper,
                repository,
                DeductionRecordDocument::fromEntity,
                DeductionRecordDocument::toEntity,
                DeductionRecord::getDeductionId,
                CACHE_NAME);
        this.repository = repository;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'driver:' + #driverId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DeductionRecord> findByDriverId(Long driverId, int page, int size) {
        requirePositive(driverId, "Driver ID");
        validatePagination(page, size);
        List<DeductionRecord> index = mapHits(repository.findByDriverId(driverId, page(page, size)));
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
        List<DeductionRecord> index = mapHits(repository.findByOffenseId(offenseId, page(page, size)));
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
        List<DeductionRecord> index = mapHits(repository.searchByHandlerPrefix(handler, page(page, size)));
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
        List<DeductionRecord> index = mapHits(repository.searchByHandlerFuzzy(handler, page(page, size)));
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
        List<DeductionRecord> index = mapHits(repository.searchByStatus(status, page(page, size)));
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
        List<DeductionRecord> index = mapHits(repository.searchByDeductionTimeRange(startTime, endTime, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<DeductionRecord> wrapper = new QueryWrapper<>();
        wrapper.between("deduction_time", start, end)
                .orderByDesc("deduction_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    private List<DeductionRecord> fetchFromDatabase(QueryWrapper<DeductionRecord> wrapper, int page, int size) {
        Page<DeductionRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        mapper().selectPage(mpPage, wrapper);
        List<DeductionRecord> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            logger().log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
            return null;
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
