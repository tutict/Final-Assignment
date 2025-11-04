package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.AuditOperationLogDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AuditOperationLogSearchRepository extends ElasticsearchRepository<AuditOperationLogDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "operationModule": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditOperationLogDocument> searchByOperationModule(String module, Pageable pageable);

    default SearchHits<AuditOperationLogDocument> searchByOperationModule(String module) {
        return searchByOperationModule(module, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "operationType": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditOperationLogDocument> searchByOperationType(String operationType, Pageable pageable);

    default SearchHits<AuditOperationLogDocument> searchByOperationType(String operationType) {
        return searchByOperationType(operationType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "userId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<AuditOperationLogDocument> findByUserId(Long userId, Pageable pageable);

    default SearchHits<AuditOperationLogDocument> findByUserId(Long userId) {
        return findByUserId(userId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "operationTime": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<AuditOperationLogDocument> searchByOperationTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<AuditOperationLogDocument> searchByOperationTimeRange(String startTime, String endTime) {
        return searchByOperationTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
