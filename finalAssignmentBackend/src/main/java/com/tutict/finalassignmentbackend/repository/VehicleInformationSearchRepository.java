package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleInformationSearchRepository extends ElasticsearchRepository<VehicleInformationDocument, Integer> {

    // Completion suggestions for licensePlate with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"licensePlate.ngram\"]}}]}}")
    SearchHits<VehicleInformationDocument> findCompletionSuggestions(String idCardNumber, String prefix, int maxSuggestions);

    // Search by licensePlate with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}]}}")
    SearchHits<VehicleInformationDocument> searchByLicensePlate(String licensePlate, String idCardNumber);

    // Search by vehicleType prefix with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"vehicleType.ngram\"]}}]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleTypePrefix(String vehicleType, String idCardNumber);

    // Fuzzy search by vehicleType with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"vehicleType.ngram\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleTypeFuzzy(String vehicleType, String idCardNumber);

    // Search by vehicleId with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"vehicleId.ngram\"]}}]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleId(String vehicleId, String idCardNumber);

    // Fuzzy search by vehicleId with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"vehicleId.ngram\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleIdFuzzy(String vehicleId, String idCardNumber);

    // Completion suggestions for vehicleId with idCardNumber filter
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"idCardNumber.keyword\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"vehicleId.ngram\"]}}]}}")
    SearchHits<VehicleInformationDocument> findVehicleIdCompletionSuggestions(String idCardNumber, String prefix, int maxSuggestions);

    // Global completion suggestions for licensePlate
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}")
    SearchHits<VehicleInformationDocument> findCompletionSuggestionsGlobally(String prefix, int maxSuggestions);

    // Global exact licensePlate search
    @Query("{\"term\": {\"licensePlate.keyword\": \"?0\"}}")
    SearchHits<VehicleInformationDocument> searchByLicensePlateExactGlobally(String licensePlate);

    // Global licensePlate fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}")
    SearchHits<VehicleInformationDocument> searchByLicensePlateGlobally(String licensePlate);

    // Global vehicleType prefix search
    @Query("{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"vehicleType.ngram\"]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleTypePrefixGlobally(String vehicleType);

    // Global vehicleType fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"vehicleType.ngram\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<VehicleInformationDocument> searchByVehicleTypeFuzzyGlobally(String vehicleType);

    // Global vehicleId prefix search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"vehicleId.ngram\"]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleIdPrefixGlobally(String vehicleId);

    // Global vehicleId fuzzy search
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"vehicleId.ngram\"], \"fuzzy_transpositions\": true, \"fuzzy_max_expansions\": 50}}")
    SearchHits<VehicleInformationDocument> searchByVehicleIdFuzzyGlobally(String vehicleId);

    // Global completion suggestions for vehicleId
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"vehicleId.ngram\"]}}")
    SearchHits<VehicleInformationDocument> findVehicleIdCompletionSuggestionsGlobally(String prefix, int maxSuggestions);
}