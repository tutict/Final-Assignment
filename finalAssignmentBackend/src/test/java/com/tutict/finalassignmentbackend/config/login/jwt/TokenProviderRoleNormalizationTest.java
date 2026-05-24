package com.tutict.finalassignmentbackend.config.login.jwt;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

class TokenProviderRoleNormalizationTest {

    @Test
    void roleAdminAliasIsAcceptedAsAdmin() {
        TokenProvider tokenProvider = tokenProvider();

        String token = tokenProvider.createToken("admin", "ROLE_ADMIN");

        assertThat(tokenProvider.extractRoles(token)).containsExactly("ROLE_ADMIN");
    }

    @Test
    void enhancedClaimsAcceptRolePrefixedAliases() {
        TokenProvider tokenProvider = tokenProvider();

        assertThatCode(() -> {
            String token = tokenProvider.createEnhancedToken(
                    "super_admin",
                    "ROLE_SUPER_ADMIN,ROLE_ADMIN",
                    "System",
                    "All"
            );

            assertThat(tokenProvider.extractRoles(token))
                    .containsExactly("ROLE_SUPER_ADMIN", "ROLE_ADMIN");
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
