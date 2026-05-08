package com.tutict.finalassignmentbackend.appeal.projection;

import com.tutict.finalassignmentbackend.appeal.read.AppealReadAssembler;
import com.tutict.finalassignmentbackend.appeal.read.AppealReadModel;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.entity.elastic.AppealRecordDocument;
import org.springframework.stereotype.Service;

@Service
public class AppealRecordProjectionAssembler {

    private final AppealReadAssembler readAssembler = new AppealReadAssembler();

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
        return readAssembler.toSearchProjection(readAssembler.fromEntity(entity));
    }

    public AppealRecordSearchProjection normalize(AppealRecordSearchProjection projection) {
        return readAssembler.toSearchProjection(readAssembler.fromProjection(projection));
    }

    public AppealRecordView toView(AppealRecordSearchProjection projection) {
        AppealReadModel model = readAssembler.fromProjection(projection);
        return readAssembler.toLegacyView(model);
    }

    public AppealRecord toLegacyEntity(AppealRecordSearchProjection projection) {
        return readAssembler.toLegacyEntity(readAssembler.fromProjection(projection));
    }
}
