package com.tutict.finalassignmentbackend.ai.prompt;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class AiAgentRoleResolverTest {

    private final AiAgentRoleResolver resolver = new AiAgentRoleResolver();

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void resolvesSuperAdminFromAuthenticatedAuthorities() {
        authenticate("ROLE_SUPER_ADMIN");

        assertThat(resolver.resolve(Map.of("roles", List.of("USER"))))
                .isEqualTo(AiAgentRole.SUPER_ADMIN);
        assertThat(resolver.resolveRoleCodes(Map.of("roles", List.of("USER"))))
                .containsExactly("SUPER_ADMIN");
    }

    @Test
    void authenticatedRolesOverrideMetadataEscalation() {
        authenticate("ROLE_USER");

        assertThat(resolver.resolve(Map.of("roles", List.of("SUPER_ADMIN"))))
                .isEqualTo(AiAgentRole.DRIVER);
        assertThat(resolver.resolveRoleCodes(Map.of("roles", List.of("SUPER_ADMIN"))))
                .containsExactly("USER");
    }

    @Test
    void fallsBackToMetadataWhenNoAuthenticationExists() {
        assertThat(resolver.resolve(Map.of("userRole", "admin")))
                .isEqualTo(AiAgentRole.ADMIN);
        assertThat(resolver.resolveRoleCodes(Map.of("roles", "ROLE_ADMIN,USER")))
                .containsExactly("ADMIN", "USER");
    }

    private static void authenticate(String... authorities) {
        UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                "tester",
                null,
                List.of(authorities).stream()
                        .map(SimpleGrantedAuthority::new)
                        .toList()
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }
}
