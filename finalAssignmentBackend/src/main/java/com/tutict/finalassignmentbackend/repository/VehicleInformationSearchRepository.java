package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface VehicleInformationSearchRepository extends ElasticsearchRepository<VehicleInformationDocument, Integer> {

    Page<VehicleInformationDocument> findByLicensePlateContainingOrVehicleTypeContainingOrOwnerNameContainingOrCurrentStatusContaining(
            String licensePlate,
            String vehicleType,
            String ownerName,
            String currentStatus,
            Pageable pageable
    );

    Optional<VehicleInformationDocument> findByLicensePlate(String licensePlate);

    List<VehicleInformationDocument> findByIdCardNumber(String idCardNumber);

    Page<VehicleInformationDocument> findByVehicleTypeContaining(String vehicleType, Pageable pageable);

    Page<VehicleInformationDocument> findByOwnerNameContaining(String ownerName, Pageable pageable);

    List<VehicleInformationDocument> findByCurrentStatus(String currentStatus);

    Page<VehicleInformationDocument> findByFirstRegistrationDateBetween(
            LocalDate startDate,
            LocalDate endDate,
            Pageable pageable
    );

    Page<VehicleInformationDocument> findByLicensePlateAndCurrentStatus(
            String licensePlate,
            String currentStatus,
            Pageable pageable
    );

    Optional<VehicleInformationDocument> findByEngineNumber(String engineNumber);

    Optional<VehicleInformationDocument> findByFrameNumber(String frameNumber);

    long countByCurrentStatus(String currentStatus);

    boolean existsByLicensePlate(String licensePlate);

    boolean existsByEngineNumber(String engineNumber);

    boolean existsByFrameNumber(String frameNumber);
}