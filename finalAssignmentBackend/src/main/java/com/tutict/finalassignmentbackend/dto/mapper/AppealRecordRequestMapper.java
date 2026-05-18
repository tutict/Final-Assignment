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
        record.setAppellantName(request.getAppellantName());
        record.setAppellantIdCard(request.getIdCard());
        record.setAppellantContact(request.getContact());
        record.setAppealType(request.getAppealType());
        record.setAppealReason(request.getAppealReason());
        record.setAppealTime(request.getAppealTime());
        return record;
    }
}
