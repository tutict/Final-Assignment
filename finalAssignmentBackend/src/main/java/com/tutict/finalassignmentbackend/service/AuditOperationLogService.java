package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.entity.AuditOperationLog;
import com.tutict.finalassignmentbackend.entity.elastic.AuditOperationLogDocument;
import com.tutict.finalassignmentbackend.mapper.AuditOperationLogMapper;
import com.tutict.finalassignmentbackend.repository.AuditOperationLogSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;

@Service
public class AuditOperationLogService extends AbstractElasticsearchCrudService<AuditOperationLog, AuditOperationLogDocument, Long> {

    private static final String CACHE_NAME = "auditOperationLogCache";

    private final AuditOperationLogSearchRepository repository;

    @Autowired
    public AuditOperationLogService(AuditOperationLogMapper mapper,
                                    AuditOperationLogSearchRepository repository) {
        super(mapper,
                repository,
                AuditOperationLogDocument::fromEntity,
                AuditOperationLogDocument::toEntity,
                AuditOperationLog::getLogId,
                CACHE_NAME);
        this.repository = repository;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'module:' + #module + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByModule(String module, int page, int size) {
        if (isBlank(module)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(repository.searchByOperationModule(module, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.like("operation_module", module)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'type:' + #type + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByOperationType(String type, int page, int size) {
        if (isBlank(type)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(repository.searchByOperationType(type, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("operation_type", type)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'user:' + #userId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> findByUserId(Long userId, int page, int size) {
        requirePositive(userId, "User ID");
        validatePagination(page, size);
        List<AuditOperationLog> index = mapHits(repository.findByUserId(userId, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'timeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditOperationLog> searchByOperationTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        List<AuditOperationLog> index = mapHits(repository.searchByOperationTimeRange(startTime, endTime, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditOperationLog> wrapper = new QueryWrapper<>();
        wrapper.between("operation_time", start, end)
                .orderByDesc("operation_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    private List<AuditOperationLog> fetchFromDatabase(QueryWrapper<AuditOperationLog> wrapper, int page, int size) {
        Page<AuditOperationLog> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        mapper().selectPage(mpPage, wrapper);
        List<AuditOperationLog> records = mpPage.getRecords();
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
