package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;

import java.util.List;

public interface OffenseInformationSearchRepository extends ElasticsearchRepository<OffenseInformationDocument, Integer> {
    List<OffenseInformationDocument> findByDriverName(String driverName);

    List<OffenseInformationDocument> findByLicensePlate(String licensePlate);

    List<OffenseInformationDocument> findByProcessStatus(String processStatus);
}