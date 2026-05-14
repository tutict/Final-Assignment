package com.tutict.finalassignmentbackend.dto.mapper;

import com.tutict.finalassignmentbackend.dto.request.AppealCreateRequest;
import com.tutict.finalassignmentbackend.entity.AppealRecord;

public final class AppealRecordRequestMapper {

    private AppealRecordRequestMapper() {
    }

    public static AppealRecord toEntity(AppealCreateRequest request) {
        if (request == null) {
            return null;
        }
        AppealRecord record = new AppealRecord();
        record.setOffenseId(request.getOffenseId());
        record.setAppealNumber(request.getAppealNumber());
        record.setAppellantName(request.getAppellantName());
        record.setAppellantIdCard(request.getAppellantIdCard());
        record.setAppellantContact(request.getAppellantContact());
        record.setAppellantEmail(request.getAppellantEmail());
        record.setAppellantAddress(request.getAppellantAddress());
        record.setAppealType(request.getAppealType());
        record.setAppealReason(request.getAppealReason());
        record.setAppealTime(request.getAppealTime());
        record.setEvidenceDescription(request.getEvidenceDescription());
        record.setEvidenceUrls(request.getEvidenceUrls());
        record.setAcceptanceStatus(request.getAcceptanceStatus());
        record.setAcceptanceTime(request.getAcceptanceTime());
        record.setAcceptanceHandler(request.getAcceptanceHandler());
        record.setRejectionReason(request.getRejectionReason());
        record.setProcessStatus(request.getProcessStatus());
        record.setProcessTime(request.getProcessTime());
        record.setProcessResult(request.getProcessResult());
        record.setProcessHandler(request.getProcessHandler());
        record.setCreatedBy(request.getCreatedBy());
        record.setUpdatedBy(request.getUpdatedBy());
        record.setRemarks(request.getRemarks());
        return record;
    }
}
