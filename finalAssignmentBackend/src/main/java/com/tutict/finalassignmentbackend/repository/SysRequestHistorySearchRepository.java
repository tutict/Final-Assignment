package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysRequestHistoryDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysRequestHistorySearchRepository extends ElasticsearchRepository<SysRequestHistoryDocument, Long> {
}
