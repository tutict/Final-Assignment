package com.tutict.finalassignmentcloud.system.appeal.read;

import com.tutict.finalassignmentcloud.system.appeal.projection.AppealRecordSearchProjection;
import com.tutict.finalassignmentcloud.system.appeal.projection.AppealRecordView;
import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

public class AppealReadAssembler {

    public AppealReadModel fromEntity(AppealRecord entity) {
        if (entity == null) {
            return null;
        }
        return normalize(new AppealReadModel(
                entity.getAppealId(),
                entity.getOffenseId(),
                entity.getDriverId(),
                entity.getAppealNumber(),
                entity.getAppellantName(),
                entity.getAppellantIdCard(),
                entity.getAppellantContact(),
                entity.getAppellantEmail(),
                entity.getAppellantAddress(),
                entity.getAppealType(),
                entity.getAppealReason(),
                entity.getAppealTime(),
                entity.getEvidenceDescription(),
                entity.getEvidenceUrls(),
                entity.getAcceptanceStatus(),
                entity.getAcceptanceTime(),
                entity.getAcceptanceHandler(),
                entity.getRejectionReason(),
                entity.getProcessStatus(),
                entity.getProcessTime(),
                entity.getProcessResult(),
                entity.getProcessHandler(),
                entity.getCreatedAt(),
                entity.getUpdatedAt(),
                entity.getCreatedBy(),
                entity.getUpdatedBy(),
                entity.getDeletedAt(),
                entity.getRemarks()
        ));
    }

    public AppealReadModel fromProjection(AppealRecordSearchProjection projection) {
        if (projection == null) {
            return null;
        }
        return normalize(new AppealReadModel(
                projection.appealId(),
                projection.offenseId(),
                projection.driverId(),
                projection.appealNumber(),
                projection.appellantName(),
                projection.appellantIdCard(),
                projection.appellantContact(),
                projection.appellantEmail(),
                projection.appellantAddress(),
                projection.appealType(),
                projection.appealReason(),
                projection.appealTime(),
                projection.evidenceDescription(),
                projection.evidenceUrls(),
                projection.acceptanceStatus(),
                projection.acceptanceTime(),
                projection.acceptanceHandler(),
                projection.rejectionReason(),
                projection.processStatus(),
                projection.processTime(),
                projection.processResult(),
                projection.processHandler(),
                projection.createdAt(),
                projection.updatedAt(),
                projection.createdBy(),
                projection.updatedBy(),
                projection.deletedAt(),
                projection.remarks()
        ));
    }

    public AppealReadModel normalize(AppealReadModel model) {
        if (model == null) {
            return null;
        }
        return new AppealReadModel(
                model.appealId(),
                model.offenseId(),
                model.driverId(),
                normalizeText(model.appealNumber()),
                normalizeText(model.appellantName()),
                normalizeText(model.appellantIdCard()),
                normalizeText(model.appellantContact()),
                normalizeText(model.appellantEmail()),
                normalizeText(model.appellantAddress()),
                normalizeText(model.appealType()),
                normalizeText(model.appealReason()),
                model.appealTime(),
                normalizeText(model.evidenceDescription()),
                normalizeText(model.evidenceUrls()),
                normalizeText(model.acceptanceStatus()),
                model.acceptanceTime(),
                normalizeText(model.acceptanceHandler()),
                normalizeText(model.rejectionReason()),
                normalizeText(model.processStatus()),
                model.processTime(),
                normalizeText(model.processResult()),
                normalizeText(model.processHandler()),
                model.createdAt(),
                model.updatedAt(),
                normalizeText(model.createdBy()),
                normalizeText(model.updatedBy()),
                model.deletedAt(),
                normalizeText(model.remarks())
        );
    }

    public AppealSearchView toSearchView(AppealReadModel model) {
        AppealReadModel normalized = normalize(model);
        if (normalized == null) {
            return null;
        }
        return new AppealSearchView(
                normalized.sourceKey(),
                normalized.appealId(),
                normalized.offenseId(),
                normalized.driverId(),
                normalized.appealNumber(),
                normalized.appellantName(),
                normalized.appealType(),
                normalized.appealReason(),
                normalized.appealTime(),
                normalized.acceptanceStatus(),
                normalized.processStatus()
        );
    }

    public AppealWorkflowView toWorkflowView(AppealReadModel model) {
        AppealReadModel normalized = normalize(model);
        if (normalized == null) {
            return null;
        }
        return new AppealWorkflowView(
                normalized.appealId(),
                normalized.acceptanceStatus(),
                normalized.acceptanceTime(),
                normalized.rejectionReason(),
                normalized.processStatus(),
                normalized.processTime(),
                normalized.processResult()
        );
    }

    public AppealRecordSearchProjection toSearchProjection(AppealReadModel model) {
        AppealReadModel normalized = normalize(model);
        if (normalized == null) {
            return null;
        }
        return new AppealRecordSearchProjection(
                normalized.appealId(),
                normalized.offenseId(),
                normalized.driverId(),
                normalized.appealNumber(),
                normalized.appellantName(),
                normalized.appellantIdCard(),
                normalized.appellantContact(),
                normalized.appellantEmail(),
                normalized.appellantAddress(),
                normalized.appealType(),
                normalized.appealReason(),
                normalized.appealTime(),
                normalized.evidenceDescription(),
                normalized.evidenceUrls(),
                normalized.acceptanceStatus(),
                normalized.acceptanceTime(),
                normalized.acceptanceHandler(),
                normalized.rejectionReason(),
                normalized.processStatus(),
                normalized.processTime(),
                normalized.processResult(),
                normalized.processHandler(),
                normalized.createdAt(),
                normalized.updatedAt(),
                normalized.createdBy(),
                normalized.updatedBy(),
                normalized.deletedAt(),
                normalized.remarks()
        );
    }

    public AppealRecordView toLegacyView(AppealReadModel model) {
        AppealSearchView view = toSearchView(model);
        if (view == null) {
            return null;
        }
        AppealReadModel normalized = normalize(model);
        return new AppealRecordView(
                view.sourceKey(),
                view.appealId(),
                view.offenseId(),
                view.appealNumber(),
                view.appellantName(),
                view.appealType(),
                view.appealReason(),
                view.appealTime(),
                view.acceptanceStatus(),
                view.processStatus(),
                normalized.acceptanceHandler(),
                normalized.processHandler()
        );
    }

    public AppealRecord toLegacyEntity(AppealReadModel model) {
        AppealReadModel normalized = normalize(model);
        if (normalized == null) {
            return null;
        }
        AppealRecord entity = new AppealRecord();
        entity.setAppealId(normalized.appealId());
        entity.setOffenseId(normalized.offenseId());
        entity.setDriverId(normalized.driverId());
        entity.setAppealNumber(normalized.appealNumber());
        entity.setAppellantName(normalized.appellantName());
        entity.setAppellantIdCard(normalized.appellantIdCard());
        entity.setAppellantContact(normalized.appellantContact());
        entity.setAppellantEmail(normalized.appellantEmail());
        entity.setAppellantAddress(normalized.appellantAddress());
        entity.setAppealType(normalized.appealType());
        entity.setAppealReason(normalized.appealReason());
        entity.setAppealTime(normalized.appealTime());
        entity.setEvidenceDescription(normalized.evidenceDescription());
        entity.setEvidenceUrls(normalized.evidenceUrls());
        entity.setAcceptanceStatus(normalized.acceptanceStatus());
        entity.setAcceptanceTime(normalized.acceptanceTime());
        entity.setAcceptanceHandler(normalized.acceptanceHandler());
        entity.setRejectionReason(normalized.rejectionReason());
        entity.setProcessStatus(normalized.processStatus());
        entity.setProcessTime(normalized.processTime());
        entity.setProcessResult(normalized.processResult());
        entity.setProcessHandler(normalized.processHandler());
        entity.setCreatedAt(normalized.createdAt());
        entity.setUpdatedAt(normalized.updatedAt());
        entity.setCreatedBy(normalized.createdBy());
        entity.setUpdatedBy(normalized.updatedBy());
        entity.setDeletedAt(normalized.deletedAt());
        entity.setRemarks(normalized.remarks());
        return entity;
    }

    public Set<String> retrievalSafeFieldNames() {
        return Set.of("appealType", "appealReason", "evidenceDescription", "remarks");
    }

    public Map<String, String> toRetrievalSafeFields(AppealReadModel model) {
        AppealReadModel normalized = normalize(model);
        if (normalized == null) {
            return Map.of();
        }
        Map<String, String> fields = new LinkedHashMap<>();
        putIfPresent(fields, "appealType", normalized.appealType());
        putIfPresent(fields, "appealReason", normalized.appealReason());
        putIfPresent(fields, "evidenceDescription", normalized.evidenceDescription());
        putIfPresent(fields, "remarks", normalized.remarks());
        return Map.copyOf(fields);
    }

    private void putIfPresent(Map<String, String> fields, String fieldName, String value) {
        if (value != null && !value.isBlank()) {
            fields.put(fieldName, value);
        }
    }

    private String normalizeText(String value) {
        return value == null ? null : value.trim();
    }
}
