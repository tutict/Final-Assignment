package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.DeductionInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DeductionInformationSearchRepository extends ElasticsearchRepository<DeductionInformationDocument, Integer> {

    // Search by handler with prefix matching
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"handler.ngram\"]}}]}}")
    SearchHits<DeductionInformationDocument> searchByHandlerPrefix(String handler);

    // Fuzzy search by handler
    @Query("{\"bool\": {\"must\": [{\"match\": {\"handler\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<DeductionInformationDocument> searchByHandlerFuzzy(String handler);

    // Search by deductionTime within a range
    @Query("{\"bool\": {\"filter\": [{\"range\": {\"deductionTime\": {\"gte\": \"?0\", \"lte\": \"?1\"}}}}}")
    SearchHits<DeductionInformationDocument> searchByDeductionTimeRange(String startTime, String endTime);
}
