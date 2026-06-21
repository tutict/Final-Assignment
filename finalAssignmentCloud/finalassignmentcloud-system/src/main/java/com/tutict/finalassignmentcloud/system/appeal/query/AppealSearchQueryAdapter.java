package com.tutict.finalassignmentcloud.system.appeal.query;

import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import com.tutict.finalassignmentcloud.system.appeal.projection.AppealRecordProjectionAssembler;
import com.tutict.finalassignmentcloud.system.appeal.query.dto.AppealPageRequest;
import com.tutict.finalassignmentcloud.system.appeal.read.AppealReadAssembler;
import com.tutict.finalassignmentcloud.system.appeal.read.AppealReadModel;
import com.tutict.finalassignmentcloud.repository.AppealRecordSearchRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Elasticsearch query adapter for Appeal records
 * Simplified version using AppealRecord directly
 */
@Service
public class AppealSearchQueryAdapter {

    private final AppealRecordSearchRepository appealRecordSearchRepository;
    private final AppealRecordProjectionAssembler projectionAssembler;
    private final AppealReadAssembler readAssembler = new AppealReadAssembler();

    public AppealSearchQueryAdapter(
            AppealRecordSearchRepository appealRecordSearchRepository,
            AppealRecordProjectionAssembler projectionAssembler
    ) {
        this.appealRecordSearchRepository = appealRecordSearchRepository;
        this.projectionAssembler = projectionAssembler;
    }

    public Optional<AppealReadModel> findById(Long appealId) {
        return appealRecordSearchRepository.findById(appealId)
                .map(projectionAssembler::fromEntity)
                .map(readAssembler::fromProjection);
    }

    public List<AppealReadModel> findByOffenseId(Long offenseId, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.findByOffenseId(offenseId, pageable(pageRequest)));
    }

    public List<AppealReadModel> findByDriverId(Long driverId, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.findByDriverId(driverId, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByAppealNumberPrefix(String appealNumber, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.findByAppealNumberStartingWith(appealNumber, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByAppealNumberFuzzy(String appealNumber, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.findByAppealNumberContaining(appealNumber, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByAppellantNamePrefix(String appellantName, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.findByAppellantNameStartingWith(appellantName, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByAppellantNameFuzzy(String appellantName, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.findByAppellantNameContaining(appellantName, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByAppellantIdCard(String appellantIdCard, AppealPageRequest pageRequest) {
        // Note: For encrypted fields, consider using blind index search
        return mapPage(appealRecordSearchRepository.findByAppealNumberContaining(appellantIdCard, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByAcceptanceStatus(String acceptanceStatus, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.findByAcceptanceStatus(acceptanceStatus, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByProcessStatus(String processStatus, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.searchByProcessStatus(processStatus, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByAppealTimeRange(
            String startTime,
            String endTime,
            AppealPageRequest pageRequest
    ) {
        return mapPage(appealRecordSearchRepository.searchByAppealTimeRange(startTime, endTime, pageable(pageRequest)));
    }

    public List<AppealReadModel> searchByAcceptanceHandler(String acceptanceHandler, AppealPageRequest pageRequest) {
        return mapPage(appealRecordSearchRepository.searchByAcceptanceHandler(acceptanceHandler, pageable(pageRequest)));
    }

    private List<AppealReadModel> mapPage(Page<AppealRecord> page) {
        if (page == null || !page.hasContent()) {
            return List.of();
        }
        return page.getContent().stream()
                .map(projectionAssembler::fromEntity)
                .map(readAssembler::fromProjection)
                .collect(Collectors.toList());
    }

    private static Pageable pageable(AppealPageRequest pageRequest) {
        return PageRequest.of(pageRequest.zeroBasedPage(), pageRequest.size());
    }
}
