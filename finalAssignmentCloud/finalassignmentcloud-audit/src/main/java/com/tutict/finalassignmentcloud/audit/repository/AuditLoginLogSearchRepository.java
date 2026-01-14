package com.tutict.finalassignmentcloud.audit.repository;

import com.tutict.finalassignmentcloud.entity.elastic.AuditLoginLogDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AuditLoginLogSearchRepository extends ElasticsearchRepository<AuditLoginLogDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "username": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditLoginLogDocument> searchByUsername(String username, Pageable pageable);

    default SearchHits<AuditLoginLogDocument> searchByUsername(String username) {
        return searchByUsername(username, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "loginResult": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditLoginLogDocument> searchByLoginResult(String loginResult, Pageable pageable);

    default SearchHits<AuditLoginLogDocument> searchByLoginResult(String loginResult) {
        return searchByLoginResult(loginResult, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "loginTime": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<AuditLoginLogDocument> searchByLoginTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<AuditLoginLogDocument> searchByLoginTimeRange(String startTime, String endTime) {
        return searchByLoginTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "loginIp": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditLoginLogDocument> searchByLoginIp(String loginIp, Pageable pageable);

    default SearchHits<AuditLoginLogDocument> searchByLoginIp(String loginIp) {
        return searchByLoginIp(loginIp, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "loginLocation": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditLoginLogDocument> searchByLoginLocation(String loginLocation, Pageable pageable);

    default SearchHits<AuditLoginLogDocument> searchByLoginLocation(String loginLocation) {
        return searchByLoginLocation(loginLocation, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "deviceType": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditLoginLogDocument> searchByDeviceType(String deviceType, Pageable pageable);

    default SearchHits<AuditLoginLogDocument> searchByDeviceType(String deviceType) {
        return searchByDeviceType(deviceType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "browserType": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AuditLoginLogDocument> searchByBrowserType(String browserType, Pageable pageable);

    default SearchHits<AuditLoginLogDocument> searchByBrowserType(String browserType) {
        return searchByBrowserType(browserType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "logoutTime": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<AuditLoginLogDocument> searchByLogoutTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<AuditLoginLogDocument> searchByLogoutTimeRange(String startTime, String endTime) {
        return searchByLogoutTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

