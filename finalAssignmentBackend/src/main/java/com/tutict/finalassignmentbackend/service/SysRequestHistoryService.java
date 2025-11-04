package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.SysRequestHistoryDocument;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.SysRequestHistorySearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class SysRequestHistoryService extends AbstractElasticsearchCrudService<SysRequestHistory, SysRequestHistoryDocument, Long> {

    private static final String CACHE_NAME = "sysRequestHistoryCache";

    private final SysRequestHistoryMapper mapper;

    @Autowired
    public SysRequestHistoryService(SysRequestHistoryMapper mapper,
                                    SysRequestHistorySearchRepository repository) {
        super(mapper,
                repository,
                SysRequestHistoryDocument::fromEntity,
                SysRequestHistoryDocument::toEntity,
                SysRequestHistory::getId,
                CACHE_NAME);
        this.mapper = mapper;
    }

    public Optional<SysRequestHistory> findByIdempotencyKey(String key) {
        return Optional.ofNullable(mapper.selectByIdempotencyKey(key));
    }
}
