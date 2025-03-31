package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.FineInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FineInformationSearchRepository extends ElasticsearchRepository<FineInformationDocument, Integer> {

    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"payee.ngram\"]}}]}}")
    SearchHits<FineInformationDocument> searchByPayeePrefix(String payee);

    @Query("{\"bool\": {\"must\": [{\"match\": {\"payee\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<FineInformationDocument> searchByPayeeFuzzy(String payee);

    @Query("{\"bool\": {\"filter\": [{\"range\": {\"fineTime\": {\"gte\": \"?0\", \"lte\": \"?1\"}}}}}")
    SearchHits<FineInformationDocument> searchByFineTimeRange(String startTime, String endTime);
}