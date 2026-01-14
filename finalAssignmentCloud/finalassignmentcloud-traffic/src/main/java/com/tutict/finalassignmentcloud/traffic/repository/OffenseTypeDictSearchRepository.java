package com.tutict.finalassignmentcloud.traffic.repository;

import com.tutict.finalassignmentcloud.entity.elastic.OffenseTypeDictDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OffenseTypeDictSearchRepository extends ElasticsearchRepository<OffenseTypeDictDocument, Integer> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "offenseCode": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<OffenseTypeDictDocument> searchByOffenseCodePrefix(String offenseCode, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchByOffenseCodePrefix(String offenseCode) {
        return searchByOffenseCodePrefix(offenseCode, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "offenseCode": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<OffenseTypeDictDocument> searchByOffenseCodeFuzzy(String offenseCode, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchByOffenseCodeFuzzy(String offenseCode) {
        return searchByOffenseCodeFuzzy(offenseCode, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "offenseName": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<OffenseTypeDictDocument> searchByOffenseNamePrefix(String offenseName, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchByOffenseNamePrefix(String offenseName) {
        return searchByOffenseNamePrefix(offenseName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "offenseName": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<OffenseTypeDictDocument> searchByOffenseNameFuzzy(String offenseName, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchByOffenseNameFuzzy(String offenseName) {
        return searchByOffenseNameFuzzy(offenseName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "category.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<OffenseTypeDictDocument> searchByCategory(String category, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchByCategory(String category) {
        return searchByCategory(category, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "severityLevel.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<OffenseTypeDictDocument> searchBySeverityLevel(String severityLevel, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchBySeverityLevel(String severityLevel) {
        return searchBySeverityLevel(severityLevel, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<OffenseTypeDictDocument> searchByStatus(String status, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchByStatus(String status) {
        return searchByStatus(status, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "standardFineAmount": {
                  "gte": ?0,
                  "lte": ?1
                }
              }
            }
            """)
    SearchHits<OffenseTypeDictDocument> searchByStandardFineAmountRange(double minAmount, double maxAmount, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchByStandardFineAmountRange(double minAmount, double maxAmount) {
        return searchByStandardFineAmountRange(minAmount, maxAmount, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "deductedPoints": {
                  "gte": ?0,
                  "lte": ?1
                }
              }
            }
            """)
    SearchHits<OffenseTypeDictDocument> searchByDeductedPointsRange(int minPoints, int maxPoints, Pageable pageable);

    default SearchHits<OffenseTypeDictDocument> searchByDeductedPointsRange(int minPoints, int maxPoints) {
        return searchByDeductedPointsRange(minPoints, maxPoints, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

