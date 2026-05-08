package com.tutict.finalassignmentbackend.appeal.projection;

import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import org.springframework.stereotype.Service;

@Service
public class AppealRecordProjectionAssembler {

    public AppealRecordSearchProjection fromDocument(AppealRecordDocument document) {
        if (document == null) {
            return null;
        }
        return new AppealRecordSearchProjection(
                document.getAppealId(),
                document.getOffenseId(),
                document.getAppealNumber(),
                document.getAppellantName(),
                document.getAppellantIdCard(),
                document.getAppellantContact(),
                document.getAppellantEmail(),
                document.getAppellantAddress(),
                document.getAppealType(),
                document.getAppealReason(),
                document.getAppealTime(),
                document.getEvidenceDescription(),
                document.getEvidenceUrls(),
                document.getAcceptanceStatus(),
                document.getAcceptanceTime(),
                document.getAcceptanceHandler(),
                document.getRejectionReason(),
                document.getProcessStatus(),
                document.getProcessTime(),
                document.getProcessResult(),
                document.getProcessHandler(),
                document.getCreatedAt(),
                document.getUpdatedAt(),
                document.getCreatedBy(),
                document.getUpdatedBy(),
                document.getDeletedAt(),
                document.getRemarks()
        );
    }

    public AppealRecordSearchProjection fromEntity(AppealRecord entity) {
        if (entity == null) {
            return null;
        }
        return new AppealRecordSearchProjection(
                entity.getAppealId(),
                entity.getOffenseId(),
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
        );
    }

    public AppealRecordSearchProjection normalize(AppealRecordSearchProjection projection) {
        if (projection == null) {
            return null;
        }
        return new AppealRecordSearchProjection(
                projection.appealId(),
                projection.offenseId(),
                normalizeText(projection.appealNumber()),
                normalizeText(projection.appellantName()),
                normalizeText(projection.appellantIdCard()),
                normalizeText(projection.appellantContact()),
                normalizeText(projection.appellantEmail()),
                normalizeText(projection.appellantAddress()),
                normalizeText(projection.appealType()),
                normalizeText(projection.appealReason()),
                projection.appealTime(),
                normalizeText(projection.evidenceDescription()),
                normalizeText(projection.evidenceUrls()),
                normalizeText(projection.acceptanceStatus()),
                projection.acceptanceTime(),
                normalizeText(projection.acceptanceHandler()),
                normalizeText(projection.rejectionReason()),
                normalizeText(projection.processStatus()),
                projection.processTime(),
                normalizeText(projection.processResult()),
                normalizeText(projection.processHandler()),
                projection.createdAt(),
                projection.updatedAt(),
                normalizeText(projection.createdBy()),
                normalizeText(projection.updatedBy()),
                projection.deletedAt(),
                normalizeText(projection.remarks())
        );
    }

    public AppealRecordView toView(AppealRecordSearchProjection projection) {
        AppealRecordSearchProjection normalized = normalize(projection);
        if (normalized == null) {
            return null;
        }
        return new AppealRecordView(
                normalized.sourceKey(),
                normalized.appealId(),
                normalized.offenseId(),
                normalized.appealNumber(),
                normalized.appellantName(),
                normalized.appealType(),
                normalized.appealReason(),
                normalized.appealTime(),
                normalized.acceptanceStatus(),
                normalized.processStatus(),
                normalized.acceptanceHandler(),
                normalized.processHandler()
        );
    }

    public AppealRecord toLegacyEntity(AppealRecordSearchProjection projection) {
        if (projection == null) {
            return null;
        }
        AppealRecord entity = new AppealRecord();
        entity.setAppealId(projection.appealId());
        entity.setOffenseId(projection.offenseId());
        entity.setAppealNumber(projection.appealNumber());
        entity.setAppellantName(projection.appellantName());
        entity.setAppellantIdCard(projection.appellantIdCard());
        entity.setAppellantContact(projection.appellantContact());
        entity.setAppellantEmail(projection.appellantEmail());
        entity.setAppellantAddress(projection.appellantAddress());
        entity.setAppealType(projection.appealType());
        entity.setAppealReason(projection.appealReason());
        entity.setAppealTime(projection.appealTime());
        entity.setEvidenceDescription(projection.evidenceDescription());
        entity.setEvidenceUrls(projection.evidenceUrls());
        entity.setAcceptanceStatus(projection.acceptanceStatus());
        entity.setAcceptanceTime(projection.acceptanceTime());
        entity.setAcceptanceHandler(projection.acceptanceHandler());
        entity.setRejectionReason(projection.rejectionReason());
        entity.setProcessStatus(projection.processStatus());
        entity.setProcessTime(projection.processTime());
        entity.setProcessResult(projection.processResult());
        entity.setProcessHandler(projection.processHandler());
        entity.setCreatedAt(projection.createdAt());
        entity.setUpdatedAt(projection.updatedAt());
        entity.setCreatedBy(projection.createdBy());
        entity.setUpdatedBy(projection.updatedBy());
        entity.setDeletedAt(projection.deletedAt());
        entity.setRemarks(projection.remarks());
        return entity;
    }

    private String normalizeText(String value) {
        return value == null ? null : value.trim();
    }
}
