package com.tutict.finalassignmentbackend.offense.governance;

import com.tutict.finalassignmentbackend.entity.OffenseRecord;

import java.util.function.Consumer;

public final class OffenseUpdateMergeCoordinator {

    private final OffenseFieldMergePolicy policy;

    public OffenseUpdateMergeCoordinator() {
        this(new OffenseFieldMergePolicy());
    }

    public OffenseUpdateMergeCoordinator(OffenseFieldMergePolicy policy) {
        this.policy = policy;
    }

    public OffenseRecord merge(OffenseRecord currentEntity,
                               OffenseRecord incomingEntity,
                               SemanticEventType semanticEventType) {
        if (semanticEventType == SemanticEventType.NO_OP) {
            return currentEntity;
        }
        if (currentEntity == null) {
            return incomingEntity;
        }
        if (incomingEntity == null) {
            return copyOf(currentEntity);
        }

        OffenseRecord merged = copyOf(currentEntity);

        apply(semanticEventType, "offenseCode", incomingEntity.getOffenseCode(), merged::setOffenseCode);
        apply(semanticEventType, "offenseTime", incomingEntity.getOffenseTime(), merged::setOffenseTime);
        apply(semanticEventType, "offenseLocation", incomingEntity.getOffenseLocation(), merged::setOffenseLocation);
        apply(semanticEventType, "offenseProvince", incomingEntity.getOffenseProvince(), merged::setOffenseProvince);
        apply(semanticEventType, "offenseCity", incomingEntity.getOffenseCity(), merged::setOffenseCity);
        apply(semanticEventType, "driverId", incomingEntity.getDriverId(), merged::setDriverId);
        apply(semanticEventType, "vehicleId", incomingEntity.getVehicleId(), merged::setVehicleId);
        apply(semanticEventType, "offenseDescription", incomingEntity.getOffenseDescription(), merged::setOffenseDescription);
        apply(semanticEventType, "evidenceType", incomingEntity.getEvidenceType(), merged::setEvidenceType);
        apply(semanticEventType, "evidenceUrls", incomingEntity.getEvidenceUrls(), merged::setEvidenceUrls);
        apply(semanticEventType, "enforcementAgency", incomingEntity.getEnforcementAgency(), merged::setEnforcementAgency);
        apply(semanticEventType, "enforcementOfficer", incomingEntity.getEnforcementOfficer(), merged::setEnforcementOfficer);
        apply(semanticEventType, "enforcementDevice", incomingEntity.getEnforcementDevice(), merged::setEnforcementDevice);
        apply(semanticEventType, "processStatus", incomingEntity.getProcessStatus(), merged::setProcessStatus);
        apply(semanticEventType, "notificationStatus", incomingEntity.getNotificationStatus(), merged::setNotificationStatus);
        apply(semanticEventType, "notificationTime", incomingEntity.getNotificationTime(), merged::setNotificationTime);
        apply(semanticEventType, "fineAmount", incomingEntity.getFineAmount(), merged::setFineAmount);
        apply(semanticEventType, "deductedPoints", incomingEntity.getDeductedPoints(), merged::setDeductedPoints);
        apply(semanticEventType, "detentionDays", incomingEntity.getDetentionDays(), merged::setDetentionDays);
        apply(semanticEventType, "processTime", incomingEntity.getProcessTime(), merged::setProcessTime);
        apply(semanticEventType, "processHandler", incomingEntity.getProcessHandler(), merged::setProcessHandler);
        apply(semanticEventType, "processResult", incomingEntity.getProcessResult(), merged::setProcessResult);
        apply(semanticEventType, "createdAt", incomingEntity.getCreatedAt(), merged::setCreatedAt);
        apply(semanticEventType, "updatedAt", incomingEntity.getUpdatedAt(), merged::setUpdatedAt);
        apply(semanticEventType, "createdBy", incomingEntity.getCreatedBy(), merged::setCreatedBy);
        apply(semanticEventType, "updatedBy", incomingEntity.getUpdatedBy(), merged::setUpdatedBy);
        apply(semanticEventType, "deletedAt", incomingEntity.getDeletedAt(), merged::setDeletedAt);
        apply(semanticEventType, "remarks", incomingEntity.getRemarks(), merged::setRemarks);

        return merged;
    }

    private <T> void apply(SemanticEventType eventType,
                           String fieldName,
                           T incomingValue,
                           Consumer<T> setter) {
        if (incomingValue != null && policy.canOverwrite(eventType, fieldName)) {
            setter.accept(incomingValue);
        }
    }

    private OffenseRecord copyOf(OffenseRecord source) {
        OffenseRecord copy = new OffenseRecord();
        copy.setOffenseId(source.getOffenseId());
        copy.setOffenseCode(source.getOffenseCode());
        copy.setOffenseNumber(source.getOffenseNumber());
        copy.setOffenseTime(source.getOffenseTime());
        copy.setOffenseLocation(source.getOffenseLocation());
        copy.setOffenseProvince(source.getOffenseProvince());
        copy.setOffenseCity(source.getOffenseCity());
        copy.setDriverId(source.getDriverId());
        copy.setVehicleId(source.getVehicleId());
        copy.setOffenseDescription(source.getOffenseDescription());
        copy.setEvidenceType(source.getEvidenceType());
        copy.setEvidenceUrls(source.getEvidenceUrls());
        copy.setEnforcementAgency(source.getEnforcementAgency());
        copy.setEnforcementOfficer(source.getEnforcementOfficer());
        copy.setEnforcementDevice(source.getEnforcementDevice());
        copy.setProcessStatus(source.getProcessStatus());
        copy.setNotificationStatus(source.getNotificationStatus());
        copy.setNotificationTime(source.getNotificationTime());
        copy.setFineAmount(source.getFineAmount());
        copy.setDeductedPoints(source.getDeductedPoints());
        copy.setDetentionDays(source.getDetentionDays());
        copy.setProcessTime(source.getProcessTime());
        copy.setProcessHandler(source.getProcessHandler());
        copy.setProcessResult(source.getProcessResult());
        copy.setCreatedAt(source.getCreatedAt());
        copy.setUpdatedAt(source.getUpdatedAt());
        copy.setCreatedBy(source.getCreatedBy());
        copy.setUpdatedBy(source.getUpdatedBy());
        copy.setDeletedAt(source.getDeletedAt());
        copy.setRemarks(source.getRemarks());
        return copy;
    }
}
