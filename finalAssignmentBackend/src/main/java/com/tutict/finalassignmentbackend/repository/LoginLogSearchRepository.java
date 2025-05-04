package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.LoginLogDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LoginLogSearchRepository extends ElasticsearchRepository<LoginLogDocument, Integer> {

    // Completion suggestions for username with loginIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"loginIpAddress.keyword\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"username\"]}}]}}")
    SearchHits<LoginLogDocument> findUsernameCompletionSuggestions(String loginIpAddress, String prefix, int maxSuggestions);

    // Search by username with loginIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"loginIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"username\"]}}]}}")
    SearchHits<LoginLogDocument> searchByUsername(String username, String loginIpAddress);

    // Search by loginResult prefix with loginIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"loginIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"loginResult\"]}}]}}")
    SearchHits<LoginLogDocument> searchByLoginResultPrefix(String loginResult, String loginIpAddress);

    // Fuzzy search by loginResult with loginIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"loginIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"loginResult\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}]}}")
    SearchHits<LoginLogDocument> searchByLoginResultFuzzy(String loginResult, String loginIpAddress);

    // Search by logId with loginIpAddress filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"loginIpAddress.keyword\": \"?1\"}}], " +
            "\"must\": [{\"term\": {\"logId\": \"?0\"}}]}}")
    SearchHits<LoginLogDocument> searchByLogId(Integer logId, String loginIpAddress);

    // Global completion suggestions for username
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"username\"]}}")
    SearchHits<LoginLogDocument> findUsernameCompletionSuggestionsGlobally(String prefix, int maxSuggestions);

    // Global exact username search
    @Query("{\"term\": {\"username.keyword\": \"?0\"}}")
    SearchHits<LoginLogDocument> searchByUsernameExactGlobally(String username);

    // Global username fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"username\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<LoginLogDocument> searchByUsernameGlobally(String username);

    // Global loginResult prefix search
    @Query("{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"loginResult\"]}}")
    SearchHits<LoginLogDocument> searchByLoginResultPrefixGlobally(String loginResult);

    // Global loginResult fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"loginResult\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<LoginLogDocument> searchByLoginResultFuzzyGlobally(String loginResult);

    // Global logId search
    @Query("{\"term\": {\"logId\": \"?0\"}}")
    SearchHits<LoginLogDocument> searchByLogIdGlobally(Integer logId);
}