package com.tutict.finalassignmentbackend.offense.governance;

import com.tutict.finalassignmentbackend.entity.OffenseRecord;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public final class FullUpdateMergePolicy {

    private final OffenseUpdateMergeCoordinator mergeCoordinator;

    public FullUpdateMergePolicy() {
        this(new OffenseUpdateMergeCoordinator());
    }

    public FullUpdateMergePolicy(OffenseUpdateMergeCoordinator mergeCoordinator) {
        this.mergeCoordinator = mergeCoordinator;
    }

    public MergeResult merge(OffenseRecord current,
                             OffenseRecord incoming,
                             FullUpdateCompatibilityMode compatibilityMode) {
        OffenseRecord merged = mergeCoordinator.merge(current, incoming, SemanticEventType.FULL_UPDATE);
        return new MergeResult(
                merged,
                compatibilityMode,
                nullPreservedFields(current, incoming),
                immutablePreservedFields(current, incoming),
                workflowSuppressedFields(current, incoming)
        );
    }

    private List<String> nullPreservedFields(OffenseRecord current, OffenseRecord incoming) {
        List<String> fields = new ArrayList<>();
        preserveIfIncomingNull(fields, "offenseCode", current == null ? null : current.getOffenseCode(), incoming == null ? null : incoming.getOffenseCode());
        preserveIfIncomingNull(fields, "offenseTime", current == null ? null : current.getOffenseTime(), incoming == null ? null : incoming.getOffenseTime());
        preserveIfIncomingNull(fields, "offenseLocation", current == null ? null : current.getOffenseLocation(), incoming == null ? null : incoming.getOffenseLocation());
        preserveIfIncomingNull(fields, "offenseProvince", current == null ? null : current.getOffenseProvince(), incoming == null ? null : incoming.getOffenseProvince());
        preserveIfIncomingNull(fields, "offenseCity", current == null ? null : current.getOffenseCity(), incoming == null ? null : incoming.getOffenseCity());
        preserveIfIncomingNull(fields, "driverId", current == null ? null : current.getDriverId(), incoming == null ? null : incoming.getDriverId());
        preserveIfIncomingNull(fields, "vehicleId", current == null ? null : current.getVehicleId(), incoming == null ? null : incoming.getVehicleId());
        preserveIfIncomingNull(fields, "offenseDescription", current == null ? null : current.getOffenseDescription(), incoming == null ? null : incoming.getOffenseDescription());
        preserveIfIncomingNull(fields, "evidenceType", current == null ? null : current.getEvidenceType(), incoming == null ? null : incoming.getEvidenceType());
        preserveIfIncomingNull(fields, "evidenceUrls", current == null ? null : current.getEvidenceUrls(), incoming == null ? null : incoming.getEvidenceUrls());
        preserveIfIncomingNull(fields, "enforcementAgency", current == null ? null : current.getEnforcementAgency(), incoming == null ? null : incoming.getEnforcementAgency());
        preserveIfIncomingNull(fields, "enforcementOfficer", current == null ? null : current.getEnforcementOfficer(), incoming == null ? null : incoming.getEnforcementOfficer());
        preserveIfIncomingNull(fields, "enforcementDevice", current == null ? null : current.getEnforcementDevice(), incoming == null ? null : incoming.getEnforcementDevice());
        preserveIfIncomingNull(fields, "notificationStatus", current == null ? null : current.getNotificationStatus(), incoming == null ? null : incoming.getNotificationStatus());
        preserveIfIncomingNull(fields, "notificationTime", current == null ? null : current.getNotificationTime(), incoming == null ? null : incoming.getNotificationTime());
        preserveIfIncomingNull(fields, "fineAmount", current == null ? null : current.getFineAmount(), incoming == null ? null : incoming.getFineAmount());
        preserveIfIncomingNull(fields, "deductedPoints", current == null ? null : current.getDeductedPoints(), incoming == null ? null : incoming.getDeductedPoints());
        preserveIfIncomingNull(fields, "detentionDays", current == null ? null : current.getDetentionDays(), incoming == null ? null : incoming.getDetentionDays());
        preserveIfIncomingNull(fields, "createdAt", current == null ? null : current.getCreatedAt(), incoming == null ? null : incoming.getCreatedAt());
        preserveIfIncomingNull(fields, "createdBy", current == null ? null : current.getCreatedBy(), incoming == null ? null : incoming.getCreatedBy());
        preserveIfIncomingNull(fields, "updatedBy", current == null ? null : current.getUpdatedBy(), incoming == null ? null : incoming.getUpdatedBy());
        preserveIfIncomingNull(fields, "deletedAt", current == null ? null : current.getDeletedAt(), incoming == null ? null : incoming.getDeletedAt());
        preserveIfIncomingNull(fields, "remarks", current == null ? null : current.getRemarks(), incoming == null ? null : incoming.getRemarks());
        return List.copyOf(fields);
    }

    private List<String> immutablePreservedFields(OffenseRecord current, OffenseRecord incoming) {
        List<String> fields = new ArrayList<>();
        preserveIfChanged(fields, "offenseId", current == null ? null : current.getOffenseId(), incoming == null ? null : incoming.getOffenseId());
        preserveIfChanged(fields, "offenseNumber", current == null ? null : current.getOffenseNumber(), incoming == null ? null : incoming.getOffenseNumber());
        return List.copyOf(fields);
    }

    private List<String> workflowSuppressedFields(OffenseRecord current, OffenseRecord incoming) {
        List<String> fields = new ArrayList<>();
        preserveIfChanged(fields, "processStatus", current == null ? null : current.getProcessStatus(), incoming == null ? null : incoming.getProcessStatus());
        preserveIfChanged(fields, "processTime", current == null ? null : current.getProcessTime(), incoming == null ? null : incoming.getProcessTime());
        preserveIfChanged(fields, "processHandler", current == null ? null : current.getProcessHandler(), incoming == null ? null : incoming.getProcessHandler());
        preserveIfChanged(fields, "processResult", current == null ? null : current.getProcessResult(), incoming == null ? null : incoming.getProcessResult());
        preserveIfChanged(fields, "updatedAt", current == null ? null : current.getUpdatedAt(), incoming == null ? null : incoming.getUpdatedAt());
        return List.copyOf(fields);
    }

    private void preserveIfIncomingNull(List<String> fields, String fieldName, Object currentValue, Object incomingValue) {
        if (currentValue != null && incomingValue == null) {
            fields.add(fieldName);
        }
    }

    private void preserveIfChanged(List<String> fields, String fieldName, Object currentValue, Object incomingValue) {
        if (incomingValue != null && !Objects.equals(currentValue, incomingValue)) {
            fields.add(fieldName);
        }
    }

    public record MergeResult(
            OffenseRecord mergedRecord,
            FullUpdateCompatibilityMode compatibilityMode,
            List<String> nullPreservedFields,
            List<String> immutablePreservedFields,
            List<String> workflowSuppressedFields
    ) {
    }
}
