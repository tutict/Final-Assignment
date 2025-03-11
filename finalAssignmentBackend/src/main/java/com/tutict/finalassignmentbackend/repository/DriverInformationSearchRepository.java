package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;

import java.util.List;

public interface DriverInformationSearchRepository extends ElasticsearchRepository<DriverInformationDocument, Integer> {
    DriverInformationDocument findByDriverLicenseNumber(String driverLicenseNumber);

    List<DriverInformationDocument> findByName(String name);

    List<DriverInformationDocument> findByIdCardNumber(String idCardNumber);
}