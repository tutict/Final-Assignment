package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleInformationSearchRepository extends ElasticsearchRepository<VehicleInformationDocument, Integer> {

    // 车牌号补全建议
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"ownerName.keyword\": \"?0\"}}}}, " +
            "\"suggest\": {\"licensePlate-suggest\": {\"prefix\": \"?1\", " +
            "\"completion\": {\"field\": \"licensePlateCompletion\", \"size\": ?2, \"skip_duplicates\": true, \"fuzzy\": {\"fuzziness\": \"1\"}}}}")
    SearchHits<VehicleInformationDocument> findCompletionSuggestions(String ownerName, String prefix, int maxSuggestions);

    // 模糊搜索车牌号
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"ownerName.keyword\": \"?1\"}}], " +
            "\"must\": [{\"match\": {\"licensePlate\": {\"query\": \"?0\", \"analyzer\": \"ik_max_word\"}}}}}")
    SearchHits<VehicleInformationDocument> searchByLicensePlate(String licensePlate, String ownerName);

    // 模糊搜索车辆类型
    @Query("{\"bool\": {\"filter\": [{\"term\": {\"ownerName.keyword\": \"?1\"}}], " +
            "\"must\": [{\"match\": {\"vehicleType\": {\"query\": \"?0\", \"analyzer\": \"ik_max_word\"}}}}}")
    SearchHits<VehicleInformationDocument> searchByVehicleType(String vehicleType, String ownerName);

    // 分页查询（可选）
    Page<VehicleInformationDocument> findByLicensePlateStartingWithAndOwnerName(String prefix, String ownerName, Pageable pageable);
}