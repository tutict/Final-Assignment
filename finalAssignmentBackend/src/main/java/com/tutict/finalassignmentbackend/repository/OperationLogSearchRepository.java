package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OperationLogDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OperationLogSearchRepository extends ElasticsearchRepository<OperationLogDocument, Integer> {

    // Completion suggestions for operationContent with userId filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"userId\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"operationContent\"]}}]}}")
    SearchHits<OperationLogDocument> findOperationContentCompletionSuggestions(Integer userId, String prefix, int maxSuggestions);

    // Search by operationContent with userId filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"userId\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"operationContent\"]}}]}}")
    SearchHits<OperationLogDocument> searchByOperationContent(String operationContent, Integer userId);

    // Search by operationResult prefix with userId filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"userId\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"operationResult\"]}}]}}")
    SearchHits<OperationLogDocument> searchByOperationResultPrefix(String operationResult, Integer userId);

    // Fuzzy search by operationResult with userId filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"userId\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"operationResult\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}]}}")
    SearchHits<OperationLogDocument> searchByOperationResultFuzzy(String operationResult, Integer userId);

    // Search by logId with userId filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"userId\": \"?1\"}}], " +
            "\"must\": [{\"term\": {\"logId\": \"?0\"}}]}}")
    SearchHits<OperationLogDocument> searchByLogId(Integer logId, Integer userId);

    // Global completion suggestions for operationContent
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"operationContent\"]}}")
    SearchHits<OperationLogDocument> findOperationContentCompletionSuggestionsGlobally(String prefix, int maxSuggestions);

    // Global exact operationContent search
    @Query("{\"term\": {\"operationContent.keyword\": \"?0\"}}")
    SearchHits<OperationLogDocument> searchByOperationContentExactGlobally(String operationContent);

    // Global operationContent fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"operationContent\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<OperationLogDocument> searchByOperationContentGlobally(String operationContent);

    // Global operationResult prefix search
    @Query("{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"operationResult\"]}}")
    SearchHits<OperationLogDocument> searchByOperationResultPrefixGlobally(String operationResult);

    // Global operationResult fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"operationResult\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<OperationLogDocument> searchByOperationResultFuzzyGlobally(String operationResult);

    // Global logId search
    @Query("{\"term\": {\"logId\": \"?0\"}}")
    SearchHits<OperationLogDocument> searchByLogIdGlobally(Integer logId);

    // Global userId search
    @Query("{\"term\": {\"userId\": \"?0\"}}")
    SearchHits<OperationLogDocument> searchByUserIdGlobally(Integer userId);
}