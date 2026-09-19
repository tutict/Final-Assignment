package com.tutict.finalassignmentcloud.traffic.service;

import com.tutict.finalassignmentcloud.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentcloud.dto.response.UserProfileResponse;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;

@Service
public class DriverAccessService {

    private final TrafficUserProfileService userProfileService;

    public DriverAccessService(TrafficUserProfileService userProfileService) {
        this.userProfileService = userProfileService;
    }

    public boolean canAccessDriver(Authentication authentication, Long driverId, Set<String> elevatedRoles) {
        if (authentication == null || driverId == null) {
            return false;
        }
        if (SecurityRoleUtils.hasAnyRole(authentication, elevatedRoles)) {
            return true;
        }
        if (!SecurityRoleUtils.hasRole(authentication, "USER")) {
            return false;
        }
        return Objects.equals(currentDriverId(authentication), driverId);
    }

    public boolean isRegularUser(Authentication authentication, Set<String> elevatedRoles) {
        return authentication != null
                && !SecurityRoleUtils.hasAnyRole(authentication, elevatedRoles)
                && SecurityRoleUtils.hasRole(authentication, "USER");
    }

    public Long currentDriverId(Authentication authentication) {
        if (authentication == null) {
            return null;
        }
        UserProfileResponse profile = userProfileService.getCurrentUserProfile(authentication);
        return profile == null ? null : profile.getDriverId();
    }

    public <T> List<T> scopedOrEmpty(Authentication authentication, Function<Long, List<T>> byDriver) {
        Long driverId = currentDriverId(authentication);
        if (driverId == null) {
            return List.of();
        }
        List<T> result = byDriver.apply(driverId);
        return result == null ? List.of() : result;
    }
}
