package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseRecordDocument;
import com.tutict.finalassignmentbackend.mapper.OffenseRecordMapper;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;

@Service
public class OffenseRecordService extends AbstractElasticsearchCrudService<OffenseRecord, OffenseRecordDocument, Long> {

    private static final String CACHE_NAME = "offenseRecordCache";

    private final OffenseInformationSearchRepository repository;

    @Autowired
    public OffenseRecordService(OffenseRecordMapper mapper,
                                OffenseInformationSearchRepository repository) {
        super(mapper,
                repository,
                OffenseRecordDocument::fromEntity,
                OffenseRecordDocument::toEntity,
                OffenseRecord::getOffenseId,
                CACHE_NAME);
        this.repository = repository;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'driver:' + #driverId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<OffenseRecord> findByDriverId(Long driverId, int page, int size) {
        requirePositive(driverId, "Driver ID");
        validatePagination(page, size);
        List<OffenseRecord> index = mapHits(repository.findByDriverId(driverId, page(page, size)));
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
        List<OffenseRecord> index = mapHits(repository.findByVehicleId(vehicleId, page(page, size)));
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
        List<OffenseRecord> index = mapHits(repository.searchByOffenseCode(offenseCode, page(page, size)));
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
        List<OffenseRecord> index = mapHits(repository.searchByProcessStatus(processStatus, page(page, size)));
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
        List<OffenseRecord> index = mapHits(repository.searchByOffenseTimeRange(startTime, endTime, page(page, size)));
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
        List<OffenseRecord> index = mapHits(repository.searchByOffenseNumber(offenseNumber, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<>();
        wrapper.like("offense_number", offenseNumber)
                .orderByDesc("offense_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    private List<OffenseRecord> fetchFromDatabase(QueryWrapper<OffenseRecord> wrapper, int page, int size) {
        Page<OffenseRecord> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        mapper().selectPage(mpPage, wrapper);
        List<OffenseRecord> records = mpPage.getRecords();
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
