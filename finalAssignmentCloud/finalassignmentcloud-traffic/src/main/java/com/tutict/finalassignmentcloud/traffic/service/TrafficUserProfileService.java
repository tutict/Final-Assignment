package com.tutict.finalassignmentcloud.traffic.service;

import com.tutict.finalassignmentcloud.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserProfile;
import com.tutict.finalassignmentcloud.dto.response.UserProfileResponse;
import com.tutict.finalassignmentcloud.entity.DriverInformation;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.exception.DependencyUnavailableException;
import com.tutict.finalassignmentcloud.traffic.client.UserClient;
import feign.FeignException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class TrafficUserProfileService {

    private static final Logger LOG = Logger.getLogger(TrafficUserProfileService.class.getName());
    private static final Set<String> DRIVER_PROFILE_ROLES = Set.of("USER");
    private static final Set<String> STAFF_ROLES = Set.of(
            "SUPER_ADMIN",
            "ADMIN",
            "TRAFFIC_POLICE",
            "FINANCE",
            "APPEAL_REVIEWER"
    );
    private static final long PROFILE_TTL_MILLIS = 60_000L;
    private static final int MAX_CACHED_PROFILES = 10_000;

    private final UserClient userClient;
    private final DriverInformationService driverInformationService;
    private final long profileTtlMillis;
    private final Map<String, CachedProfile> profiles = new ConcurrentHashMap<>();

    @Autowired
    public TrafficUserProfileService(UserClient userClient,
                                     DriverInformationService driverInformationService) {
        this(userClient, driverInformationService, PROFILE_TTL_MILLIS);
    }

    TrafficUserProfileService(UserClient userClient,
                              DriverInformationService driverInformationService,
                              long profileTtlMillis) {
        this.userClient = userClient;
        this.driverInformationService = driverInformationService;
        this.profileTtlMillis = profileTtlMillis;
    }

    public UserProfileResponse getCurrentUserProfile(Authentication authentication) {
        if (authentication == null || !StringUtils.hasText(authentication.getName())) {
            throw new IllegalArgumentException("Authenticated user is required");
        }
        SysUser user = safeGetByUsername(authentication.getName());
        if (user == null) {
            throw new IllegalStateException("User not found: " + authentication.getName());
        }

        List<String> roles = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .map(SecurityRoleUtils::normalizeRoleCode)
                .filter(role -> !role.isBlank())
                .distinct()
                .toList();
        DriverInformation driver = resolveDriverForUser(user, roles);

        return UserProfileResponse.builder()
                .authUserId(user.getUserId())
                .username(user.getUsername())
                .displayName(resolveDisplayName(user))
                .email(user.getEmail())
                .phoneNumber(maskPhone(user.getContactNumber()))
                .roles(roles)
                .driverId(driver != null ? driver.getDriverId() : null)
                .driverName(driver != null ? driver.getName() : null)
                .build();
    }

    private DriverInformation resolveDriverForUser(SysUser user, List<String> roles) {
        if (shouldOwnDriverProfile(roles)) {
            return driverInformationService.findOrCreateLinkedDriver(user);
        }
        return null;
    }

    private boolean shouldOwnDriverProfile(List<String> roles) {
        if (roles == null || roles.isEmpty()) {
            return false;
        }
        boolean userRole = roles.stream().anyMatch(DRIVER_PROFILE_ROLES::contains);
        boolean staffRole = roles.stream().anyMatch(STAFF_ROLES::contains);
        return userRole && !staffRole;
    }

    private SysUser safeGetByUsername(String username) {
        long now = System.currentTimeMillis();
        CachedProfile cached = profiles.get(username);
        if (cached != null && cached.expiresAt() > now) {
            return cached.user();
        }
        try {
            InternalUserProfile profile = userClient.getByUsername(username);
            if (profile == null) {
                profiles.remove(username);
                return null;
            }
            SysUser user = profile.toEntity();
            if (profiles.size() >= MAX_CACHED_PROFILES) {
                profiles.clear();
            }
            profiles.put(username, new CachedProfile(user, now + profileTtlMillis));
            return user;
        } catch (FeignException.NotFound ex) {
            profiles.remove(username);
            return null;
        } catch (FeignException ex) {
            if (cached != null) {
                LOG.log(Level.WARNING, "Serving cached user profile for " + username + " after lookup failure", ex);
                return cached.user();
            }
            LOG.log(Level.WARNING, "Failed to fetch user by username=" + username, ex);
            throw new DependencyUnavailableException("user-service profile lookup failed for " + username, ex);
        }
    }

    private String resolveDisplayName(SysUser user) {
        if (user == null) {
            return null;
        }
        return StringUtils.hasText(user.getRealName()) ? user.getRealName() : user.getUsername();
    }

    private String maskPhone(String phoneNumber) {
        if (!StringUtils.hasText(phoneNumber)) {
            return phoneNumber;
        }
        String trimmed = phoneNumber.trim();
        if (trimmed.length() < 7) {
            return trimmed.charAt(0) + "****";
        }
        return trimmed.substring(0, 3) + "****" + trimmed.substring(trimmed.length() - 4);
    }

    private record CachedProfile(SysUser user, long expiresAt) {
    }
}
