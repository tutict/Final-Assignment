package com.tutict.finalassignmentcloud.traffic.service;

import com.tutict.finalassignmentcloud.dto.response.UserProfileResponse;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DriverAccessServiceTest {

    @Test
    void elevatedRolesBypassDriverCheck() {
        DriverAccessService service = new DriverAccessService(mock(TrafficUserProfileService.class));
        Authentication admin = auth("admin", "ROLE_ADMIN");
        assertFalse(service.isRegularUser(admin, Set.of("ADMIN", "SUPER_ADMIN", "TRAFFIC_POLICE")));
        assertTrue(service.canAccessDriver(admin, 1L, Set.of("ADMIN")));
    }

    @Test
    void userCanOnlyAccessBoundDriver() {
        TrafficUserProfileService profiles = mock(TrafficUserProfileService.class);
        Authentication user = auth("driver", "ROLE_USER");
        when(profiles.getCurrentUserProfile(user)).thenReturn(UserProfileResponse.builder().driverId(7L).build());
        DriverAccessService service = new DriverAccessService(profiles);
        Set<String> elevated = Set.of("ADMIN", "SUPER_ADMIN", "TRAFFIC_POLICE");
        assertTrue(service.isRegularUser(user, elevated));
        assertTrue(service.canAccessDriver(user, 7L, elevated));
        assertFalse(service.canAccessDriver(user, 8L, elevated));
        assertEquals(7L, service.currentDriverId(user));
        assertEquals(List.of("own-7"), service.scopedOrEmpty(user, id -> List.of("own-" + id)));
    }

    @Test
    void userWithoutBindingSeesEmptyScope() {
        TrafficUserProfileService profiles = mock(TrafficUserProfileService.class);
        Authentication user = auth("driver", "USER");
        when(profiles.getCurrentUserProfile(user)).thenReturn(UserProfileResponse.builder().build());
        DriverAccessService service = new DriverAccessService(profiles);
        assertTrue(service.scopedOrEmpty(user, id -> List.of("x")).isEmpty());
        assertFalse(service.canAccessDriver(user, 1L, Set.of("ADMIN")));
    }

    private static Authentication auth(String name, String role) {
        return new UsernamePasswordAuthenticationToken(name, "n/a", List.of(new SimpleGrantedAuthority(role)));
    }
}
