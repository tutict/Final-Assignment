package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleInformationSearchRepository extends ElasticsearchRepository<VehicleInformationDocument, Integer> {

    // 使用 query_string 查询，支持更灵活的模糊匹配
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"ownerName.keyword\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"licensePlate.ngram\"]}}]}}")
    SearchHits<VehicleInformationDocument> findCompletionSuggestions(String ownerName, String prefix, int maxSuggestions);

    // 使用 query_string 查询，支持更灵活的模糊匹配
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"ownerName.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}]}}")
    SearchHits<VehicleInformationDocument> searchByLicensePlate(String licensePlate, String ownerName);

    // 模糊搜索车辆类型
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"ownerName.keyword\": \"?1\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"vehicleType.ngram\"]}}]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleTypePrefix(String vehicleType, String ownerName);

    // 模糊匹配查询
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"ownerName.keyword\": \"?1\"}}], " +
            "\"must\": [{\"match\": {\"vehicleType\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleTypeFuzzy(String vehicleType, String ownerName);

    // 使用 query_string 查询，支持全局车牌号的模糊匹配
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}")
    SearchHits<VehicleInformationDocument> findCompletionSuggestionsGlobally(String prefix, int maxSuggestions);

    @Query("{\"term\": {\"licensePlate.keyword\": \"?0\"}}")
    SearchHits<VehicleInformationDocument> searchByLicensePlateExactGlobally(String licensePlate);

    // 使用 query_string 查询，支持全局车牌号的模糊匹配
    @Query("{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}")
    SearchHits<VehicleInformationDocument> searchByLicensePlateGlobally(String licensePlate);

    // 模糊搜索车辆类型前缀，全局范围
    @Query("{\"query_string\": {\"query\": \"?0*\", \"fields\": [\"vehicleType.ngram\"]}}")
    SearchHits<VehicleInformationDocument> searchByVehicleTypePrefixGlobally(String vehicleType);

    // 模糊匹配查询车辆类型，全局范围
    @Query("{\"match\": {\"vehicleType\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}")
    SearchHits<VehicleInformationDocument> searchByVehicleTypeFuzzyGlobally(String vehicleType);
}