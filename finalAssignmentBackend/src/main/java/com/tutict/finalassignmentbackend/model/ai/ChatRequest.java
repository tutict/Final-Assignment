package com.tutict.finalassignmentbackend.model.ai;

import jakarta.validation.constraints.NotBlank;

public record ChatRequest(
        @NotBlank(message = "message is required")
        String message,
        String massage,
        boolean webSearch
) {
}
