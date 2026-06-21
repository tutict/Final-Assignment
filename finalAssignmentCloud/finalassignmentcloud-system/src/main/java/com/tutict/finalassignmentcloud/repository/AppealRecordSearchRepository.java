package com.tutict.finalassignmentcloud.repository;

import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

/**
 * Appeal Record Elasticsearch Repository
 * Provides search capabilities for appeal records
 */
@Repository
public interface AppealRecordSearchRepository extends ElasticsearchRepository<AppealRecord, Long> {

    // Search by offense ID
    Page<AppealRecord> findByOffenseId(Long offenseId, Pageable pageable);

    // Search by driver ID
    Page<AppealRecord> findByDriverId(Long driverId, Pageable pageable);

    // Search by appeal number (prefix match)
    Page<AppealRecord> findByAppealNumberStartingWith(String appealNumber, Pageable pageable);

    // Search by appeal number (fuzzy match)
    Page<AppealRecord> findByAppealNumberContaining(String appealNumber, Pageable pageable);

    // Search by appellant name (prefix match)
    Page<AppealRecord> findByAppellantNameStartingWith(String appellantName, Pageable pageable);

    // Search by appellant name (fuzzy match)
    Page<AppealRecord> findByAppellantNameContaining(String appellantName, Pageable pageable);

    // Search by acceptance status
    Page<AppealRecord> findByAcceptanceStatus(String acceptanceStatus, Pageable pageable);

    // Search by process status
    Page<AppealRecord> searchByProcessStatus(String processStatus, Pageable pageable);

    // Search by appeal time range
    Page<AppealRecord> searchByAppealTimeRange(String startTime, String endTime, Pageable pageable);

    // Search by acceptance handler
    Page<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, Pageable pageable);
}
