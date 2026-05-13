package com.tutict.finalassignmentbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RefreshRequest {

    @NotBlank(message = "refreshToken must not be blank")
    private String refreshToken;
}
