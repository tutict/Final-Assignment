package com.tutict.finalassignmentcloud.repository;

import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

/**
 * Appeal Record Elasticsearch Repository
 * Provides search capabilities for appeal records
 */
@Repository
public interface AppealRecordSearchRepository extends ElasticsearchRepository<AppealRecord, Long> {
    // Elasticsearch repository methods are auto-generated
    // Custom query methods can be added here if needed
}
