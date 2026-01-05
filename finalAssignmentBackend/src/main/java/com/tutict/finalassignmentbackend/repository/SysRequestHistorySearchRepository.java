package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysRequestHistoryDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysRequestHistorySearchRepository extends ElasticsearchRepository<SysRequestHistoryDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "idempotencyKey": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysRequestHistoryDocument> searchByIdempotencyKey(String key, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> searchByIdempotencyKey(String key) {
        return searchByIdempotencyKey(key, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysRequestHistoryDocument> searchByRequestMethod(String requestMethod, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> searchByRequestMethod(String requestMethod) {
        return searchByRequestMethod(requestMethod, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysRequestHistoryDocument> searchByRequestUrlPrefix(String requestUrl, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> searchByRequestUrlPrefix(String requestUrl) {
        return searchByRequestUrlPrefix(requestUrl, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "businessType.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysRequestHistoryDocument> searchByBusinessType(String businessType, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> searchByBusinessType(String businessType) {
        return searchByBusinessType(businessType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "businessId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysRequestHistoryDocument> findByBusinessId(Long businessId, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> findByBusinessId(Long businessId) {
        return findByBusinessId(businessId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "businessStatus.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysRequestHistoryDocument> searchByBusinessStatus(String businessStatus, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> searchByBusinessStatus(String businessStatus) {
        return searchByBusinessStatus(businessStatus, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysRequestHistoryDocument> findByUserId(Long userId, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> findByUserId(Long userId) {
        return findByUserId(userId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "requestIp": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysRequestHistoryDocument> searchByRequestIp(String requestIp, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> searchByRequestIp(String requestIp) {
        return searchByRequestIp(requestIp, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "createdAt": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<SysRequestHistoryDocument> searchByCreatedAtRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<SysRequestHistoryDocument> searchByCreatedAtRange(String startTime, String endTime) {
        return searchByCreatedAtRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
