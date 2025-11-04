package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.DeductionRecordDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DeductionRecordSearchRepository extends ElasticsearchRepository<DeductionRecordDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "term": {
                "driverId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<DeductionRecordDocument> findByDriverId(Long driverId, Pageable pageable);

    default SearchHits<DeductionRecordDocument> findByDriverId(Long driverId) {
        return findByDriverId(driverId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "offenseId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<DeductionRecordDocument> findByOffenseId(Long offenseId, Pageable pageable);

    default SearchHits<DeductionRecordDocument> findByOffenseId(Long offenseId) {
        return findByOffenseId(offenseId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "handler": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<DeductionRecordDocument> searchByHandlerPrefix(String handler, Pageable pageable);

    default SearchHits<DeductionRecordDocument> searchByHandlerPrefix(String handler) {
        return searchByHandlerPrefix(handler, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "handler": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<DeductionRecordDocument> searchByHandlerFuzzy(String handler, Pageable pageable);

    default SearchHits<DeductionRecordDocument> searchByHandlerFuzzy(String handler) {
        return searchByHandlerFuzzy(handler, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "status.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<DeductionRecordDocument> searchByStatus(String status, Pageable pageable);

    default SearchHits<DeductionRecordDocument> searchByStatus(String status) {
        return searchByStatus(status, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "deductionTime": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<DeductionRecordDocument> searchByDeductionTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<DeductionRecordDocument> searchByDeductionTimeRange(String startTime, String endTime) {
        return searchByDeductionTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
