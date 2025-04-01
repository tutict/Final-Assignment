package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OffenseInformationSearchRepository extends ElasticsearchRepository<OffenseInformationDocument, Integer> {

    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"offenseType.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByOffenseTypePrefix(String offenseType);

    @Query("{\"bool\": {\"must\": [{\"match\": {\"offenseType\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<OffenseInformationDocument> searchByOffenseTypeFuzzy(String offenseType);

    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByLicensePlate(String licensePlate);

    @Query("{\"bool\": {\"must\": [{\"match\": {\"licensePlate\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<OffenseInformationDocument> searchByLicensePlateFuzzy(String licensePlate);

    @Query("{\"bool\": {\"filter\": [{\"term\": {\"processStatus.keyword\": \"?0\"}}]}}")
    SearchHits<OffenseInformationDocument> searchByProcessStatus(String processStatus);

    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"driverName.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByDriverNamePrefix(String driverName);

    @Query("{\"bool\": {\"must\": [{\"match\": {\"driverName\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<OffenseInformationDocument> searchByDriverNameFuzzy(String driverName);

    // Custom aggregation for violation type counts
    @Query("{\"bool\": {\"filter\": [{\"range\": {\"offenseTime\": {\"gte\": \"?0\"}}]}, " +
            "\"aggs\": {\"by_type\": {\"terms\": {\"field\": \"offenseType.keyword\", \"size\": 10}}}}")
    SearchHits<OffenseInformationDocument> aggregateByOffenseType(String fromTime);

    // Custom aggregation for time-series data
    @Query("{\"bool\": {\"filter\": [{\"range\": {\"offenseTime\": {\"gte\": \"?0\"}}]}, " +
            "\"aggs\": {\"by_day\": {\"date_histogram\": {\"field\": \"offenseTime\", \"calendar_interval\": \"day\"}, " +
            "\"aggs\": {\"total_fine\": {\"sum\": {\"field\": \"fineAmount\"}}, " +
            "\"total_points\": {\"sum\": {\"field\": \"deductedPoints\"}}}}}}")
    SearchHits<OffenseInformationDocument> aggregateByDate(String fromTime);
}