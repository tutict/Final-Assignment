package com.tutict.finalassignmentcloud.audit.repository;

import com.tutict.finalassignmentcloud.entity.elastic.AuditOperationLogDocument;
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

    @Query("""
            {
              "match_phrase_prefix": {
                "username": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditOperationLogDocument> searchByUsername(String username, Pageable pageable);

    default SearchHits<AuditOperationLogDocument> searchByUsername(String username) {
        return searchByUsername(username, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "requestUrl": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditOperationLogDocument> searchByRequestUrl(String requestUrl, Pageable pageable);

    default SearchHits<AuditOperationLogDocument> searchByRequestUrl(String requestUrl) {
        return searchByRequestUrl(requestUrl, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "requestMethod.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<AuditOperationLogDocument> searchByRequestMethod(String requestMethod, Pageable pageable);

    default SearchHits<AuditOperationLogDocument> searchByRequestMethod(String requestMethod) {
        return searchByRequestMethod(requestMethod, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "operationResult.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<AuditOperationLogDocument> searchByOperationResult(String operationResult, Pageable pageable);

    default SearchHits<AuditOperationLogDocument> searchByOperationResult(String operationResult) {
        return searchByOperationResult(operationResult, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

