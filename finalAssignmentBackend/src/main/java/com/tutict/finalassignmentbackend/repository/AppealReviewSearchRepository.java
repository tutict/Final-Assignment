package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.AppealReviewDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppealReviewSearchRepository extends ElasticsearchRepository<AppealReviewDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "term": {
                "appealId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<AppealReviewDocument> findByAppealId(Long appealId, Pageable pageable);

    default SearchHits<AppealReviewDocument> findByAppealId(Long appealId) {
        return findByAppealId(appealId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "reviewLevel.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<AppealReviewDocument> findByReviewLevel(String reviewLevel, Pageable pageable);

    default SearchHits<AppealReviewDocument> findByReviewLevel(String reviewLevel) {
        return findByReviewLevel(reviewLevel, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "reviewResult.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<AppealReviewDocument> findByReviewResult(String reviewResult, Pageable pageable);

    default SearchHits<AppealReviewDocument> findByReviewResult(String reviewResult) {
        return findByReviewResult(reviewResult, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
