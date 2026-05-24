package com.tutict.finalassignmentbackend.config.login.jwt;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

class TokenProviderRoleNormalizationTest {

    @Test
    void adminRoleIsIssuedWithSpringAuthorityPrefix() {
        TokenProvider tokenProvider = tokenProvider();

        String token = tokenProvider.createToken("admin", "ADMIN");

        assertThat(tokenProvider.extractRoles(token)).containsExactly("ROLE_" + "ADMIN");
    }

    @Test
    void enhancedClaimsUseCanonicalAdminRoles() {
        TokenProvider tokenProvider = tokenProvider();

        assertThatCode(() -> {
            String token = tokenProvider.createEnhancedToken(
                    "super_admin",
                    "SUPER_ADMIN,ADMIN",
                    "System",
                    "All"
            );

            assertThat(tokenProvider.extractRoles(token))
                    .containsExactly("ROLE_" + "SUPER_ADMIN", "ROLE_" + "ADMIN");
        }).doesNotThrowAnyException();
    }

    private TokenProvider tokenProvider() {
        TokenProvider tokenProvider = new TokenProvider();
        ReflectionTestUtils.setField(tokenProvider, "secret",
                "0123456789abcdef0123456789abcdef");
        ReflectionTestUtils.setField(tokenProvider, "configuredAlgorithm", "HS256");
        ReflectionTestUtils.setField(tokenProvider, "accessTokenExpirationSeconds", 3600L);
        tokenProvider.init();
        return tokenProvider;
    }
}
