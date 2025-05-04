package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SystemLogsDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SystemLogsSearchRepository extends ElasticsearchRepository<SystemLogsDocument, Integer> {

    // Completion suggestions for logContent with operationIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"operationIpAddress.keyword\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"logContent\"]}}]}}")
    SearchHits<SystemLogsDocument> findLogContentCompletionSuggestions(String operationIpAddress, String prefix, int maxSuggestions);

    // Completion suggestions for operationUser with operationIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"operationIpAddress.keyword\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"operationUser\"]}}]}}")
    SearchHits<SystemLogsDocument> findOperationUserCompletionSuggestions(String operationIpAddress, String prefix, int maxSuggestions);

    // Search by logContent with operationIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"operationIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"logContent\"]}}]}}")
    SearchHits<SystemLogsDocument> searchByLogContent(String logContent, String operationIpAddress);

    // Search by operationUser with operationIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"operationIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"operationUser\"]}}]}}")
    SearchHits<SystemLogsDocument> searchByOperationUser(String operationUser, String operationIpAddress);

    // Search by logType prefix with operationIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"operationIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"logType\"]}}]}}")
    SearchHits<SystemLogsDocument> searchByLogTypePrefix(String logType, String operationIpAddress);

    // Fuzzy search by logType with operationIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"operationIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"logType\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}]}}")
    SearchHits<SystemLogsDocument> searchByLogTypeFuzzy(String logType, String operationIpAddress);

    // Search by logId with operationIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"operationIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"term\": {\"logId\": \"?0\"}}]}}")
    SearchHits<SystemLogsDocument> searchByLogId(Integer logId, String operationIpAddress);

    // Global completion suggestions for logContent
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"logContent\"]}}")
    SearchHits<SystemLogsDocument> findLogContentCompletionSuggestionsGlobally(String prefix, int maxSuggestions);

    // Global completion suggestions for operationUser
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"operationUser\"]}}")
    SearchHits<SystemLogsDocument> findOperationUserCompletionSuggestionsGlobally(String prefix, int maxSuggestions);

    // Global exact logContent search
    @Query("{\"term\": {\"logContent.keyword\": \"?0\"}}")
    SearchHits<SystemLogsDocument> searchByLogContentExactGlobally(String logContent);

    // Global logContent fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"logContent\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<SystemLogsDocument> searchByLogContentGlobally(String logContent);

    // Global exact operationUser search
    @Query("{\"term\": {\"operationUser.keyword\": \"?0\"}}")
    SearchHits<SystemLogsDocument> searchByOperationUserExactGlobally(String operationUser);

    // Global operationUser fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"operationUser\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<SystemLogsDocument> searchByOperationUserGlobally(String operationUser);

    // Global logType prefix search
    @Query("{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"logType\"]}}")
    SearchHits<SystemLogsDocument> searchByLogTypePrefixGlobally(String logType);

    // Global logType fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"logType\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<SystemLogsDocument> searchByLogTypeFuzzyGlobally(String logType);

    // Global logId search
    @Query("{\"term\": {\"logId\": \"?0\"}}")
    SearchHits<SystemLogsDocument> searchByLogIdGlobally(Integer logId);
}