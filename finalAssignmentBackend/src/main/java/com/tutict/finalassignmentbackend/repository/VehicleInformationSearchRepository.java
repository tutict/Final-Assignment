package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;

public interface VehicleInformationSearchRepository extends ElasticsearchRepository<VehicleInformationDocument, Integer> {
    Page<VehicleInformationDocument> findByLicensePlateContainingOrVehicleTypeContainingOrOwnerNameContainingOrCurrentStatusContaining(
            String licensePlate, String vehicleType, String ownerName, String currentStatus, Pageable pageable);
}