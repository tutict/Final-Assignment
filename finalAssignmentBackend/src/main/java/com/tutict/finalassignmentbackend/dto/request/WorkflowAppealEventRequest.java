package com.tutict.finalassignmentbackend.dto.request;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class WorkflowAppealEventRequest {

    @Size(max = 500, message = "驳回原因不能超过 500 字")
    private String reason;
}
