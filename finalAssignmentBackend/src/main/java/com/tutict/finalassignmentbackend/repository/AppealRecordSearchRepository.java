package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
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
}
