package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DriverInformationSearchRepository extends ElasticsearchRepository<DriverInformationDocument, Integer> {

    Page<DriverInformationDocument> findByNameContainingOrDriverLicenseNumberContainingOrContactNumberContaining(
            String name,
            String driverLicenseNumber,
            String contactNumber,
            Pageable pageable
    );


    Optional<DriverInformationDocument> findByIdCardNumber(String idCardNumber);

    List<DriverInformationDocument> findByContactNumber(String contactNumber);

    Page<DriverInformationDocument> findByGender(String gender, Pageable pageable);

    Page<DriverInformationDocument> findByAllowedVehicleType(String allowedVehicleType, Pageable pageable);

    Page<DriverInformationDocument> findByBirthdateBetween(
            LocalDate startDate,
            LocalDate endDate,
            Pageable pageable
    );

    Page<DriverInformationDocument> findByIssueDateBetween(
            LocalDate startDate,
            LocalDate endDate,
            Pageable pageable
    );

    Page<DriverInformationDocument> findByExpiryDateBetween(
            LocalDate startDate,
            LocalDate endDate,
            Pageable pageable
    );

    Page<DriverInformationDocument> findByNameContaining(String name, Pageable pageable);

    boolean existsByDriverLicenseNumber(String driverLicenseNumber);

    boolean existsByIdCardNumber(String idCardNumber);

    long countByGender(String gender);

    long countByAllowedVehicleType(String allowedVehicleType);
}