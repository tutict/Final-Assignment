package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OffenseInformationSearchRepository extends ElasticsearchRepository<OffenseInformationDocument, Integer> {

    Page<OffenseInformationDocument> findByLicensePlateContainingOrDriverNameContainingOrOffenseTypeContainingOrProcessStatusContaining(
            String licensePlate,
            String driverName,
            String offenseType,
            String processStatus,
            Pageable pageable
    );

    Optional<OffenseInformationDocument> findByOffenseId(Integer offenseId);

    Page<OffenseInformationDocument> findByLicensePlate(String licensePlate, Pageable pageable);

    Page<OffenseInformationDocument> findByDriverId(Integer driverId, Pageable pageable);

    Page<OffenseInformationDocument> findByVehicleId(Integer vehicleId, Pageable pageable);


    Page<OffenseInformationDocument> findByOffenseTimeBetween(
            LocalDateTime startTime,
            LocalDateTime endTime,
            Pageable pageable
    );

    Page<OffenseInformationDocument> findByProcessStatus(String processStatus, Pageable pageable);

    Page<OffenseInformationDocument> findByOffenseType(String offenseType, Pageable pageable);

    Page<OffenseInformationDocument> findByFineAmountBetween(
            BigDecimal minAmount,
            BigDecimal maxAmount,
            Pageable pageable
    );

    Page<OffenseInformationDocument> findByDeductedPoints(Integer deductedPoints, Pageable pageable);

    long countByProcessStatus(String processStatus);

    long countByOffenseType(String offenseType);

    List<OffenseInformationDocument> findByProcessStatusOrderByFineAmount(String processStatus);

    boolean existsByOffenseId(Integer offenseId);
}