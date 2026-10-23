package com.tutict.finalassignmentcloud.traffic.dto;

import jakarta.validation.constraints.Size;

public class WorkflowAppealEventRequest {

    @Size(max = 500, message = "驳回原因不能超过 500 字")
    private String reason;

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }
}
