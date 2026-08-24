package com.tutict.finalassignmentcloud.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Token 刷新响应，与 monolith 的 TokenResponse 保持契约一致。
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TokenResponse {

    private String accessToken;
    private String refreshToken;
    private long expiresIn;
    @Builder.Default
    private String tokenType = "Bearer";
}