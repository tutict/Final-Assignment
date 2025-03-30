package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OffenseInformationSearchRepository extends ElasticsearchRepository<OffenseInformationDocument, Integer> {

    // 使用 query_string 查询，支持更灵活的模糊匹配，按 driverName 精确匹配并模糊搜索 offenseType
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"offenseType.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByOffenseTypePrefix(String offenseType);

    // 模糊匹配查询 offenseType
    @Query("{\"bool\": {\"must\": [{\"match\": {\"offenseType\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<OffenseInformationDocument> searchByOffenseTypeFuzzy(String offenseType);

    // 使用 query_string 查询，支持更灵活的模糊匹配，按 licensePlate 模糊搜索
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"licensePlate.ngram\"]}}]}}")
    SearchHits<OffenseInformationDocument> searchByLicensePlate(String licensePlate);

    // 按 processStatus 精确匹配
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"processStatus.keyword\": \"?0\"}}]}}")
    SearchHits<OffenseInformationDocument> searchByProcessStatus(String processStatus);
}