package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverInformationSearchRepository extends ElasticsearchRepository<DriverInformationDocument, Integer> {

    // 使用 query_string 查询，支持更灵活的模糊匹配，按 driverLicenseNumber 模糊搜索
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"driverLicenseNumber.ngram\"]}}]}}")
    SearchHits<DriverInformationDocument> searchByDriverLicenseNumber(String driverLicenseNumber);

    // 使用 query_string 查询，支持更灵活的模糊匹配，按 name 模糊搜索
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"name.ngram\"]}}]}}")
    SearchHits<DriverInformationDocument> searchByNamePrefix(String name);

    // 模糊匹配查询 name
    @Query("{\"bool\": {\"must\": [{\"match\": {\"name\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<DriverInformationDocument> searchByNameFuzzy(String name);

    // 使用 query_string 查询，支持更灵活的模糊匹配，按 idCardNumber 模糊搜索
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"idCardNumber.ngram\"]}}]}}")
    SearchHits<DriverInformationDocument> searchByIdCardNumber(String idCardNumber);
}