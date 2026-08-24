package com.tutict.finalassignmentcloud.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Token 刷新请求，与 monolith 的 RefreshRequest 保持契约一致。
 */
@Data
public class RefreshRequest {

    @NotBlank(message = "refreshToken must not be blank")
    private String refreshToken;
}