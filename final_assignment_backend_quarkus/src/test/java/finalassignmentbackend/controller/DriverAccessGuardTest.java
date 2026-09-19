package finalassignmentbackend.controller;

import finalassignmentbackend.dto.UserProfileResponse;
import finalassignmentbackend.service.auth.AuthWsService;
import jakarta.ws.rs.core.SecurityContext;
import org.junit.jupiter.api.Test;

import java.security.Principal;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DriverAccessGuardTest {

    @Test
    void elevatedRolesBypassDriverCheck() {
        DriverAccessGuard guard = new DriverAccessGuard(new StubAuth(99L));
        assertTrue(guard.isElevated(ctx("admin", Set.of("ADMIN"))));
        assertTrue(guard.canAccessDriver(ctx("admin", Set.of("SUPER_ADMIN")), 1L));
        assertFalse(guard.isElevated(ctx("user", Set.of("USER"))));
    }

    @Test
    void userCanOnlyAccessBoundDriver() {
        DriverAccessGuard guard = new DriverAccessGuard(new StubAuth(7L));
        SecurityContext user = ctx("driver", Set.of("USER"));
        assertTrue(guard.canAccessDriver(user, 7L));
        assertFalse(guard.canAccessDriver(user, 8L));
        assertEquals(7L, guard.currentDriverId(user));
        assertEquals(1, guard.scopedOrEmpty(user, id -> java.util.List.of("own-" + id)).size());
    }

    @Test
    void userWithoutBindingSeesEmptyScope() {
        DriverAccessGuard guard = new DriverAccessGuard(new StubAuth(null));
        SecurityContext user = ctx("driver", Set.of("USER"));
        assertFalse(guard.canAccessDriver(user, 1L));
        assertTrue(guard.scopedOrEmpty(user, id -> java.util.List.of("x")).isEmpty());
    }

    private static SecurityContext ctx(String name, Set<String> roles) {
        return new SecurityContext() {
            @Override
            public Principal getUserPrincipal() {
                return () -> name;
            }

            @Override
            public boolean isUserInRole(String role) {
                return roles.contains(role);
            }

            @Override
            public boolean isSecure() {
                return false;
            }

            @Override
            public String getAuthenticationScheme() {
                return "Bearer";
            }
        };
    }

    private static final class StubAuth extends AuthWsService {
        private final Long driverId;

        private StubAuth(Long driverId) {
            this.driverId = driverId;
        }

        @Override
        public UserProfileResponse getCurrentUserProfile(String username) {
            return UserProfileResponse.builder().username(username).driverId(driverId).build();
        }
    }
}