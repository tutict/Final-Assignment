package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.entity.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.elastic.AuditLoginLogDocument;
import com.tutict.finalassignmentbackend.mapper.AuditLoginLogMapper;
import com.tutict.finalassignmentbackend.repository.AuditLoginLogSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.logging.Level;

@Service
public class AuditLoginLogService extends AbstractElasticsearchCrudService<AuditLoginLog, AuditLoginLogDocument, Long> {

    private static final String CACHE_NAME = "auditLoginLogCache";

    private final AuditLoginLogSearchRepository repository;

    @Autowired
    public AuditLoginLogService(AuditLoginLogMapper mapper,
                                AuditLoginLogSearchRepository repository) {
        super(mapper,
                repository,
                AuditLoginLogDocument::fromEntity,
                AuditLoginLogDocument::toEntity,
                AuditLoginLog::getLogId,
                CACHE_NAME);
        this.repository = repository;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'username:' + #username + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditLoginLog> searchByUsername(String username, int page, int size) {
        if (isBlank(username)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditLoginLog> index = mapHits(repository.searchByUsername(username, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.like("username", username)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'result:' + #loginResult + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditLoginLog> searchByLoginResult(String loginResult, int page, int size) {
        if (isBlank(loginResult)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditLoginLog> index = mapHits(repository.searchByLoginResult(loginResult, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.eq("login_result", loginResult)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'timeRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditLoginLog> searchByLoginTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        List<AuditLoginLog> index = mapHits(repository.searchByLoginTimeRange(startTime, endTime, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.between("login_time", start, end)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'ip:' + #loginIp + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<AuditLoginLog> searchByLoginIp(String loginIp, int page, int size) {
        if (isBlank(loginIp)) {
            return List.of();
        }
        validatePagination(page, size);
        List<AuditLoginLog> index = mapHits(repository.searchByLoginIp(loginIp, page(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<AuditLoginLog> wrapper = new QueryWrapper<>();
        wrapper.like("login_ip", loginIp)
                .orderByDesc("login_time");
        return fetchFromDatabase(wrapper, page, size);
    }

    private List<AuditLoginLog> fetchFromDatabase(QueryWrapper<AuditLoginLog> wrapper, int page, int size) {
        Page<AuditLoginLog> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        mapper().selectPage(mpPage, wrapper);
        List<AuditLoginLog> records = mpPage.getRecords();
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
