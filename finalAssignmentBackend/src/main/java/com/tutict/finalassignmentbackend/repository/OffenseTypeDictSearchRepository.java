package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OffenseTypeDictDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OffenseTypeDictSearchRepository extends ElasticsearchRepository<OffenseTypeDictDocument, Integer> {
}
