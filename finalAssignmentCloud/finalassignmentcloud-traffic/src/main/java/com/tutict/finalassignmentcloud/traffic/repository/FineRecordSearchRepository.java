package com.tutict.finalassignmentcloud.traffic.repository;

import com.tutict.finalassignmentcloud.entity.elastic.FineRecordDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FineRecordSearchRepository extends ElasticsearchRepository<FineRecordDocument, Long> {

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
    SearchHits<FineRecordDocument> findByOffenseId(Long offenseId, Pageable pageable);

    default SearchHits<FineRecordDocument> findByOffenseId(Long offenseId) {
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
    SearchHits<FineRecordDocument> searchByHandlerPrefix(String handler, Pageable pageable);

    default SearchHits<FineRecordDocument> searchByHandlerPrefix(String handler) {
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
    SearchHits<FineRecordDocument> searchByHandlerFuzzy(String handler, Pageable pageable);

    default SearchHits<FineRecordDocument> searchByHandlerFuzzy(String handler) {
        return searchByHandlerFuzzy(handler, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "paymentStatus": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<FineRecordDocument> searchByPaymentStatus(String paymentStatus, Pageable pageable);

    default SearchHits<FineRecordDocument> searchByPaymentStatus(String paymentStatus) {
        return searchByPaymentStatus(paymentStatus, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "fineDate": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<FineRecordDocument> searchByFineDateRange(String startDate, String endDate, Pageable pageable);

    default SearchHits<FineRecordDocument> searchByFineDateRange(String startDate, String endDate) {
        return searchByFineDateRange(startDate, endDate, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

