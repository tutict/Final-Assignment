package com.tutict.finalassignmentbackend.appeal.query;

import com.tutict.finalassignmentbackend.appeal.projection.AppealRecordProjectionAssembler;
import com.tutict.finalassignmentbackend.appeal.query.dto.AppealPageRequest;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import com.tutict.finalassignmentbackend.repository.AppealRecordSearchRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class AppealSearchQueryAdapter {

    private final AppealRecordSearchRepository appealRecordSearchRepository;
    private final AppealRecordProjectionAssembler projectionAssembler;

    public AppealSearchQueryAdapter(
            AppealRecordSearchRepository appealRecordSearchRepository,
            AppealRecordProjectionAssembler projectionAssembler
    ) {
        this.appealRecordSearchRepository = appealRecordSearchRepository;
        this.projectionAssembler = projectionAssembler;
    }

    public Optional<AppealRecord> findById(Long appealId) {
        return appealRecordSearchRepository.findById(appealId)
                .map(projectionAssembler::fromDocument)
                .map(projectionAssembler::toLegacyEntity);
    }

    public List<AppealRecord> findByOffenseId(Long offenseId, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.findByOffenseId(offenseId, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByAppealNumberPrefix(String appealNumber, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.searchByAppealNumberPrefix(appealNumber, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByAppealNumberFuzzy(String appealNumber, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.searchByAppealNumberFuzzy(appealNumber, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByAppellantNamePrefix(String appellantName, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.searchByAppellantNamePrefix(appellantName, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByAppellantNameFuzzy(String appellantName, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.searchByAppellantNameFuzzy(appellantName, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByAppellantIdCard(String appellantIdCard, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.searchByAppellantIdCard(appellantIdCard, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByAcceptanceStatus(String acceptanceStatus, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.searchByAcceptanceStatus(acceptanceStatus, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByProcessStatus(String processStatus, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.searchByProcessStatus(processStatus, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByAppealTimeRange(
            String startTime,
            String endTime,
            AppealPageRequest pageRequest
    ) {
        return mapHits(appealRecordSearchRepository.searchByAppealTimeRange(startTime, endTime, pageable(pageRequest)));
    }

    public List<AppealRecord> searchByAcceptanceHandler(String acceptanceHandler, AppealPageRequest pageRequest) {
        return mapHits(appealRecordSearchRepository.searchByAcceptanceHandler(acceptanceHandler, pageable(pageRequest)));
    }

    private List<AppealRecord> mapHits(SearchHits<AppealRecordDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(SearchHit::getContent)
                .map(projectionAssembler::fromDocument)
                .map(projectionAssembler::toLegacyEntity)
                .collect(Collectors.toList());
    }

    private static Pageable pageable(AppealPageRequest pageRequest) {
        return PageRequest.of(pageRequest.zeroBasedPage(), pageRequest.size());
    }
}
