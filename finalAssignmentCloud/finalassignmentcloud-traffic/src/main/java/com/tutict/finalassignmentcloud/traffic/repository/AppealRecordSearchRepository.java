package com.tutict.finalassignmentcloud.traffic.repository;

import com.tutict.finalassignmentcloud.entity.elastic.AppealRecordDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppealRecordSearchRepository extends ElasticsearchRepository<AppealRecordDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "term": {
                "offenseId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> findByOffenseId(Long offenseId, Pageable pageable);

    default SearchHits<AppealRecordDocument> findByOffenseId(Long offenseId) {
        return findByOffenseId(offenseId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "appealNumber": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByAppealNumberPrefix(String appealNumber, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByAppealNumberPrefix(String appealNumber) {
        return searchByAppealNumberPrefix(appealNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "appealNumber": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByAppealNumberFuzzy(String appealNumber, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByAppealNumberFuzzy(String appealNumber) {
        return searchByAppealNumberFuzzy(appealNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "appellantName": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByAppellantNamePrefix(String appellantName, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByAppellantNamePrefix(String appellantName) {
        return searchByAppellantNamePrefix(appellantName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "appellantName": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByAppellantNameFuzzy(String appellantName, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByAppellantNameFuzzy(String appellantName) {
        return searchByAppellantNameFuzzy(appellantName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "appellantIdCard": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByAppellantIdCard(String appellantIdCard, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByAppellantIdCard(String appellantIdCard) {
        return searchByAppellantIdCard(appellantIdCard, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "acceptanceStatus.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByAcceptanceStatus(String acceptanceStatus, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByAcceptanceStatus(String acceptanceStatus) {
        return searchByAcceptanceStatus(acceptanceStatus, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "processStatus.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByProcessStatus(String processStatus, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByProcessStatus(String processStatus) {
        return searchByProcessStatus(processStatus, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "appealTime": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByAppealTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByAppealTimeRange(String startTime, String endTime) {
        return searchByAppealTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "acceptanceHandler": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<AppealRecordDocument> searchByAcceptanceHandler(String acceptanceHandler, Pageable pageable);

    default SearchHits<AppealRecordDocument> searchByAcceptanceHandler(String acceptanceHandler) {
        return searchByAcceptanceHandler(acceptanceHandler, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

