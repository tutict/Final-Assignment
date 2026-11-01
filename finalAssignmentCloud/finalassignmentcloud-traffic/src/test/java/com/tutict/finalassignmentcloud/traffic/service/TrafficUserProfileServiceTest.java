package com.tutict.finalassignmentcloud.traffic.service;

import com.tutict.finalassignmentcloud.dto.internal.InternalUserProfile;
import com.tutict.finalassignmentcloud.dto.response.UserProfileResponse;
import com.tutict.finalassignmentcloud.exception.DependencyUnavailableException;
import com.tutict.finalassignmentcloud.traffic.client.UserClient;
import feign.FeignException;
import feign.Request;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class TrafficUserProfileServiceTest {

    private final UserClient userClient = mock(UserClient.class);
    private final DriverInformationService driverInformationService = mock(DriverInformationService.class);

    @Test
    void repeatedLookupsWithinTtlUseCache() {
        when(userClient.getByUsername("ce@ce.com")).thenReturn(profile("ce@ce.com"));
        TrafficUserProfileService service = new TrafficUserProfileService(userClient, driverInformationService);

        UserProfileResponse first = service.getCurrentUserProfile(driver());
        UserProfileResponse second = service.getCurrentUserProfile(driver());

        assertEquals("ce@ce.com", first.getDisplayName());
        assertEquals("ce@ce.com", second.getDisplayName());
        verify(userClient, times(1)).getByUsername("ce@ce.com");
    }

    @Test
    void lookupFailureWithoutCacheIsReportedAsDependencyUnavailable() {
        when(userClient.getByUsername(anyString())).thenThrow(unavailable());
        TrafficUserProfileService service = new TrafficUserProfileService(userClient, driverInformationService);

        assertThrows(DependencyUnavailableException.class, () -> service.getCurrentUserProfile(driver()));
        verify(userClient, times(1)).getByUsername(anyString());
    }

    @Test
    void lookupFailureFallsBackToExpiredCache() {
        when(userClient.getByUsername("ce@ce.com"))
                .thenReturn(profile("ce@ce.com"))
                .thenThrow(unavailable());
        TrafficUserProfileService service = new TrafficUserProfileService(userClient, driverInformationService, -1L);

        assertEquals("ce@ce.com", service.getCurrentUserProfile(driver()).getDisplayName());
        assertEquals("ce@ce.com", service.getCurrentUserProfile(driver()).getDisplayName());
        verify(userClient, times(2)).getByUsername("ce@ce.com");
    }

    @Test
    void missingUserIsNotTreatedAsDependencyFailure() {
        when(userClient.getByUsername(anyString())).thenThrow(notFound());
        TrafficUserProfileService service = new TrafficUserProfileService(userClient, driverInformationService);

        IllegalStateException error = assertThrows(IllegalStateException.class,
                () -> service.getCurrentUserProfile(driver()));
        assertTrue(error.getMessage().contains("User not found"));
    }

    private static Authentication driver() {
        return new UsernamePasswordAuthenticationToken("ce@ce.com", null,
                List.of(new SimpleGrantedAuthority("ROLE_USER")));
    }

    private static InternalUserProfile profile(String username) {
        InternalUserProfile profile = new InternalUserProfile();
        profile.setUserId(26L);
        profile.setUsername(username);
        profile.setRealName(username);
        profile.setEmail(username);
        return profile;
    }

    private static Request request() {
        return Request.create(Request.HttpMethod.GET,
                "http://finalassignmentcloud-user/api/users/internal/profile/username/ce%40ce.com",
                Map.of(), null, StandardCharsets.UTF_8);
    }

    private static FeignException unavailable() {
        return new FeignException.ServiceUnavailable("load shed", request(),
                "{\"errorCode\":\"LOAD_SHED\"}".getBytes(StandardCharsets.UTF_8),
                Map.of("content-type", List.of("application/json")));
    }

    private static FeignException notFound() {
        return new FeignException.NotFound("missing", request(), null, Map.of());
    }
}
