package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppealManagementSearchRepository extends ElasticsearchRepository<AppealManagementDocument, Integer> {

    // 使用 query_string 查询，支持更灵活的模糊匹配，按 appellantName 模糊搜索
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"appellantName.ngram\"]}}]}}")
    SearchHits<AppealManagementDocument> searchByAppellantNamePrefix(String appellantName);

    // 模糊匹配查询 appellantName
    @Query("{\"bool\": {\"must\": [{\"match\": {\"appellantName\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<AppealManagementDocument> searchByAppellantNameFuzzy(String appellantName);

    // 使用 query_string 查询，支持更灵活的模糊匹配，按 appealReason 模糊搜索
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"appealReason.ngram\"]}}]}}")
    SearchHits<AppealManagementDocument> searchByAppealReasonPrefix(String appealReason);

    // 模糊匹配查询 appealReason
    @Query("{\"bool\": {\"must\": [{\"match\": {\"appealReason\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<AppealManagementDocument> searchByAppealReasonFuzzy(String appealReason);

    // 使用 query_string 查询，支持更灵活的模糊匹配，按 appealId 模糊搜索
    @Query("{\"bool\": {\"must\": [{\"query_string\": {\"query\": \"*?0*\", \"fields\": [\"appealId.ngram\"]}}]}}")
    SearchHits<AppealManagementDocument> searchByAppealIdPrefix(String appealId);

    // 模糊匹配查询 appealId
    @Query("{\"bool\": {\"must\": [{\"match\": {\"appealId\": {\"query\": \"?0\", \"fuzziness\": \"AUTO\"}}}]}}")
    SearchHits<AppealManagementDocument> searchByAppealIdFuzzy(String appealId);

    // New aggregation method with query_string
    @Query("{\"bool\": {\"filter\": [{\"range\": {\"appealTime\": {\"gte\": \"?0\"}}], " +
            "\"must\": [{\"query_string\": {\"query\": \"*?1*\", \"fields\": [\"appealReason.ngram\"]}}]}, " +
            "\"aggs\": {\"by_reason\": {\"terms\": {\"field\": \"appealReason.keyword\", \"size\": 10}}}}")
    SearchHits<AppealManagementDocument> aggregateByAppealReason(String fromTime, String appealReason);

    // 按 processStatus 精确匹配
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"processStatus.keyword\": \"?0\"}}]}}")
    SearchHits<AppealManagementDocument> searchByProcessStatus(String processStatus);
}