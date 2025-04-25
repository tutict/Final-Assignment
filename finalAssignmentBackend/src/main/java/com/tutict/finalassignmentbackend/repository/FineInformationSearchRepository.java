package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.FineInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FineInformationSearchRepository extends ElasticsearchRepository<FineInformationDocument, Integer> {

    // Search by payee with prefix matching
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"payee.ngram\"]}}]}}")
    SearchHits<FineInformationDocument> searchByPayeePrefix(String payee);

    // Fuzzy search by payee
    @Query("{\"bool\": {\"must\": [{\"match\": {\"payee\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<FineInformationDocument> searchByPayeeFuzzy(String payee);

    // Search by fineId with prefix matching
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"fineId.ngram\"]}}]}}")
    SearchHits<FineInformationDocument> searchByFineIdPrefix(String fineId);

    // Fuzzy search by fineId
    @Query("{\"bool\": {\"must\": [{\"match\": {\"fineId\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<FineInformationDocument> searchByFineIdFuzzy(String fineId);

    // Search by fineTime within a range
    @Query("{\"bool\": {\"filter\": [{\"range\": {\"fineTime\": {\"gte\": \"?0\", \"lte\": \"?1\"}}}}}")
    SearchHits<FineInformationDocument> searchByFineTimeRange(String startTime, String endTime);

    // Aggregation method for payment status
    @Query("{\"bool\": {\"filter\": [{\"range\": {\"fineTime\": {\"gte\": \"?0\"}}]}, " +
            "\"aggs\": {\"by_paid\": {\"terms\": {\"field\": \"receiptNumber.keyword\", \"missing\": \"unpaid\", \"size\": 2}}}}")
    SearchHits<FineInformationDocument> aggregateByPaymentStatus(String fromTime);
}