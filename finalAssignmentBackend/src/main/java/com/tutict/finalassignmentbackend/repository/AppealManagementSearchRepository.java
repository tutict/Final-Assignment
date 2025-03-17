package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppealManagementSearchRepository extends ElasticsearchRepository<AppealManagementDocument, Integer> {

    // Custom query to search across multiple fields with OR condition
    @Query("{\"bool\": {\"should\": [" +
            "{\"match\": {\"appellantName\": \"?0\"}}," +
            "{\"match\": {\"appealReason\": \"?0\"}}," +
            "{\"match\": {\"processStatus\": \"?0\"}}" +
            "], \"minimum_should_match\": 1}}")
    Page<AppealManagementDocument> findByAppellantNameContainingOrAppealReasonContainingOrProcessStatusContaining(
            String query, Pageable pageable);
}