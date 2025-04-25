package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OffenseInformationSearchRepository extends ElasticsearchRepository<OffenseInformationDocument, Integer> {

    // Search by offenseType with prefix matching
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"offenseType.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByOffenseTypePrefix(String offenseType);

    // Fuzzy search by offenseType
    @Query("{\"bool\": {\"must\": [{\"match\": {\"offenseType\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<OffenseInformationDocument> searchByOffenseTypeFuzzy(String offenseType);

    // Search by licensePlate with prefix matching
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByLicensePlate(String licensePlate);

    // Fuzzy search by licensePlate
    @Query("{\"bool\": {\"must\": [{\"match\": {\"licensePlate\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<OffenseInformationDocument> searchByLicensePlateFuzzy(String licensePlate);

    // Search by driverName with prefix matching
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"driverName.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByDriverNamePrefix(String driverName);

    // Fuzzy search by driverName
    @Query("{\"bool\": {\"must\": [{\"match\": {\"driverName\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<OffenseInformationDocument> searchByDriverNameFuzzy(String driverName);

    // Search by offenseId with prefix matching
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"offenseId.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByOffenseIdPrefix(String offenseId);

    // Fuzzy search by offenseId
    @Query("{\"bool\": {\"must\": [{\"match\": {\"offenseId\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<OffenseInformationDocument> searchByOffenseIdFuzzy(String offenseId);

    // Aggregate by date with driverName filter
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"?1\", \"fields\": [\"driverName.keyword\"], \"default_operator\": \"AND\"}}], " +
            "\"filter\": [{\"range\": {\"offenseTime\": {\"gte\": \"?0\", \"format\": \"yyyy-MM-dd'T'HH:mm:ss\"}}}]}," +
            "\"aggs\": {\"by_day\": {\"date_histogram\": {" +
            "    \"field\": \"offenseTime\", \"calendar_interval\": \"day\", \"format\": \"yyyy-MM-dd\"}," +
            "    \"aggs\": {\"total_fine\": {\"sum\": {\"field\": \"fineAmount\"}}," +
            "             \"total_points\": {\"sum\": {\"field\": \"deductedPoints\"}}}" +
            "}}}")
    SearchHits<OffenseInformationDocument> aggregateByDate(String fromTime, String driverName);

    // Aggregate by date without driverName filter
    @Query("{\"bool\": {\"filter\": [{\"range\": {\"offenseTime\": {\"gte\": \"?0\", \"format\": \"yyyy-MM-dd'T'HH:mm:ss\"}}}]}," +
            "\"aggs\": {\"by_day\": {\"date_histogram\": {" +
            "    \"field\": \"offenseTime\", \"calendar_interval\": \"day\", \"format\": \"yyyy-MM-dd\"}," +
            "    \"aggs\": {\"total_fine\": {\"sum\": {\"field\": \"fineAmount\"}}," +
            "             \"total_points\": {\"sum\": {\"field\": \"deductedPoints\"}}}" +
            "}}}")
    SearchHits<OffenseInformationDocument> aggregateByDate(String fromTime);
}