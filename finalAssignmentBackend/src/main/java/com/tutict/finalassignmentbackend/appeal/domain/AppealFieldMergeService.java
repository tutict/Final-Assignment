package com.tutict.finalassignmentbackend.appeal.domain;

import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealFieldMutationPolicy;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import org.springframework.stereotype.Service;

import java.util.Objects;

@Service
public class AppealFieldMergeService {

    private final AppealFieldMutationPolicy mutationPolicy;

    public AppealFieldMergeService() {
        this(new AppealFieldMutationPolicy());
    }

    public AppealFieldMergeService(AppealFieldMutationPolicy mutationPolicy) {
        this.mutationPolicy = mutationPolicy;
    }

    public AppealRecord merge(AppealRecord existing, AppealRecord incoming) {
        Objects.requireNonNull(existing, "Existing appeal record cannot be null");
        Objects.requireNonNull(incoming, "Incoming appeal record cannot be null");
        boolean terminalState = mutationPolicy.isTerminalState(existing);
        AppealRecord merged = new AppealRecord();

        merged.setAppealId(mutationPolicy.preserveExisting(existing.getAppealId()));
        merged.setOffenseId(mutationPolicy.preserveExisting(existing.getOffenseId()));
        merged.setAppealNumber(mutationPolicy.preserveExisting(existing.getAppealNumber()));
        merged.setAppealTime(mutationPolicy.preserveExisting(existing.getAppealTime()));

        merged.setAppellantName(mergeMutable("appellantName", existing.getAppellantName(), incoming.getAppellantName(), terminalState));
        merged.setAppellantIdCard(mergeMutable("appellantIdCard", existing.getAppellantIdCard(), incoming.getAppellantIdCard(), terminalState));
        merged.setAppellantContact(mergeMutable("appellantContact", existing.getAppellantContact(), incoming.getAppellantContact(), terminalState));
        merged.setAppellantEmail(mergeMutable("appellantEmail", existing.getAppellantEmail(), incoming.getAppellantEmail(), terminalState));
        merged.setAppellantAddress(mergeMutable("appellantAddress", existing.getAppellantAddress(), incoming.getAppellantAddress(), terminalState));
        merged.setAppealType(mergeMutable("appealType", existing.getAppealType(), incoming.getAppealType(), terminalState));
        merged.setAppealReason(mergeMutable("appealReason", existing.getAppealReason(), incoming.getAppealReason(), terminalState));
        merged.setEvidenceDescription(mergeMutable("evidenceDescription", existing.getEvidenceDescription(), incoming.getEvidenceDescription(), terminalState));
        merged.setEvidenceUrls(mergeMutable("evidenceUrls", existing.getEvidenceUrls(), incoming.getEvidenceUrls(), terminalState));
        merged.setRemarks(mergeMutable("remarks", existing.getRemarks(), incoming.getRemarks(), terminalState));

        merged.setAcceptanceStatus(mutationPolicy.preserveExisting(existing.getAcceptanceStatus()));
        merged.setAcceptanceTime(mutationPolicy.preserveExisting(existing.getAcceptanceTime()));
        merged.setAcceptanceHandler(mutationPolicy.preserveExisting(existing.getAcceptanceHandler()));
        merged.setRejectionReason(mutationPolicy.preserveExisting(existing.getRejectionReason()));
        merged.setProcessStatus(mutationPolicy.preserveExisting(existing.getProcessStatus()));
        merged.setProcessTime(mutationPolicy.preserveExisting(existing.getProcessTime()));
        merged.setProcessResult(mutationPolicy.preserveExisting(existing.getProcessResult()));
        merged.setProcessHandler(mutationPolicy.preserveExisting(existing.getProcessHandler()));
        merged.setCreatedAt(mutationPolicy.preserveExisting(existing.getCreatedAt()));
        merged.setUpdatedAt(mutationPolicy.preserveExisting(existing.getUpdatedAt()));
        merged.setCreatedBy(mutationPolicy.preserveExisting(existing.getCreatedBy()));
        merged.setUpdatedBy(mutationPolicy.preserveExisting(existing.getUpdatedBy()));
        merged.setDeletedAt(mutationPolicy.preserveExisting(existing.getDeletedAt()));
        return merged;
    }

    private String mergeMutable(String fieldName, String existingValue, String incomingValue, boolean terminalState) {
        return mutationPolicy.mergeMutableField(fieldName, existingValue, incomingValue, terminalState);
    }
}
