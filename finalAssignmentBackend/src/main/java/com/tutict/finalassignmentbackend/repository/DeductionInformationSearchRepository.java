package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.DeductionInformationDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DeductionInformationSearchRepository extends ElasticsearchRepository<DeductionInformationDocument, Integer> {
}
