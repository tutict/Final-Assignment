package com.tutict.finalassignmentcloud.traffic.service;

import com.tutict.finalassignmentcloud.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentcloud.dto.response.UserProfileResponse;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.util.Objects;
import java.util.Set;

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
        UserProfileResponse profile = userProfileService.getCurrentUserProfile(authentication);
        return Objects.equals(profile.getDriverId(), driverId);
    }

    public boolean isRegularUser(Authentication authentication, Set<String> elevatedRoles) {
        return authentication != null
                && !SecurityRoleUtils.hasAnyRole(authentication, elevatedRoles)
                && SecurityRoleUtils.hasRole(authentication, "USER");
    }
}
