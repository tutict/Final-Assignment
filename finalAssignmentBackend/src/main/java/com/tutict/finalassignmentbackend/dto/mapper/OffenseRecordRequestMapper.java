package com.tutict.finalassignmentbackend.dto.mapper;

import com.tutict.finalassignmentbackend.dto.request.OffenseCreateRequest;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;

public final class OffenseRecordRequestMapper {

    private OffenseRecordRequestMapper() {
    }

    public static OffenseRecord toEntity(OffenseCreateRequest request) {
        if (request == null) {
            return null;
        }
        OffenseRecord record = new OffenseRecord();
        record.setOffenseCode(request.getOffenseCode());
        record.setOffenseNumber(request.getOffenseNumber());
        record.setOffenseTime(request.getOffenseTime());
        record.setOffenseLocation(request.getOffenseLocation());
        record.setOffenseProvince(request.getOffenseProvince());
        record.setOffenseCity(request.getOffenseCity());
        record.setDriverId(request.getDriverId());
        record.setVehicleId(request.getVehicleId());
        record.setOffenseDescription(request.getOffenseDescription());
        record.setEvidenceType(request.getEvidenceType());
        record.setEvidenceUrls(request.getEvidenceUrls());
        record.setEnforcementAgency(request.getEnforcementAgency());
        record.setEnforcementOfficer(request.getEnforcementOfficer());
        record.setEnforcementDevice(request.getEnforcementDevice());
        record.setProcessStatus(request.getProcessStatus());
        record.setNotificationStatus(request.getNotificationStatus());
        record.setNotificationTime(request.getNotificationTime());
        record.setFineAmount(request.getFineAmount());
        record.setDeductedPoints(request.getDeductedPoints());
        record.setDetentionDays(request.getDetentionDays());
        record.setProcessTime(request.getProcessTime());
        record.setProcessHandler(request.getProcessHandler());
        record.setProcessResult(request.getProcessResult());
        record.setCreatedBy(request.getCreatedBy());
        record.setUpdatedBy(request.getUpdatedBy());
        record.setRemarks(request.getRemarks());
        return record;
    }
}
