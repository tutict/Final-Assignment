package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.UserManagementDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserManagementSearchRepository extends ElasticsearchRepository<UserManagementDocument, Integer> {

    // Completion suggestions for username with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"username\"]}}]}}")
    SearchHits<UserManagementDocument> findUsernameCompletionSuggestions(String idCardNumber, String prefix, int maxSuggestions);

    // Search by username with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"username\"]}}]}}")
    SearchHits<UserManagementDocument> searchByUsername(String username, String idCardNumber);

    // Search by email prefix with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"email\"]}}]}}")
    SearchHits<UserManagementDocument> searchByEmailPrefix(String email, String idCardNumber);

    // Fuzzy search by email with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"email\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}]}}")
    SearchHits<UserManagementDocument> searchByEmailFuzzy(String email, String idCardNumber);

    // Search by userId with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"term\": {\"userId\": \"?0\"}}]}}")
    SearchHits<UserManagementDocument> searchByUserId(Integer userId, String idCardNumber);

    // Global completion suggestions for username
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"username\"]}}")
    SearchHits<UserManagementDocument> findUsernameCompletionSuggestionsGlobally(String prefix, int maxSuggestions);

    // Global exact username search
    @Query("{\"term\": {\"username.keyword\": \"?0\"}}")
    SearchHits<UserManagementDocument> searchByUsernameExactGlobally(String username);

    // Global username fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"username\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<UserManagementDocument> searchByUsernameGlobally(String username);

    // Global email prefix search
    @Query("{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"email\"]}}")
    SearchHits<UserManagementDocument> searchByEmailPrefixGlobally(String email);

    // Global email fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"email\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<UserManagementDocument> searchByEmailFuzzyGlobally(String email);

    // Global userId search
    @Query("{\"term\": {\"userId\": \"?0\"}}")
    SearchHits<UserManagementDocument> searchByUserIdGlobally(Integer userId);

    // Global exact status search
    @Query("{\"term\": {\"status.keyword\": \"?0\"}}")
    SearchHits<UserManagementDocument> searchByStatusExactGlobally(String status);

    // Global status fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"status\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<UserManagementDocument> searchByStatusGlobally(String status);

    // Global exact phoneNumber search
    @Query("{\"term\": {\"phoneNumber.keyword\": \"?0\"}}")
    SearchHits<UserManagementDocument> searchByPhoneNumberExactGlobally(String phoneNumber);

    // Global phoneNumber fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"phoneNumber\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<UserManagementDocument> searchByPhoneNumberGlobally(String phoneNumber);

    // Global phoneNumber prefix search
    @Query("{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"phoneNumber\"]}}")
    SearchHits<UserManagementDocument> searchByPhoneNumberPrefixGlobally(String phoneNumber);
}