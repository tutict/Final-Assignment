package finalassignmentbackend.controller;

import finalassignmentbackend.dto.UserProfileResponse;
import finalassignmentbackend.service.AuthWsService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.SecurityContext;

import java.util.Objects;
import java.util.Set;

@ApplicationScoped
public class DriverAccessGuard {
    private static final Set<String> ELEVATED_ROLES = Set.of("SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER");

    @Inject
    AuthWsService authWsService;

    public boolean canAccessDriver(SecurityContext securityContext, Long driverId) {
        if (securityContext == null || securityContext.getUserPrincipal() == null || driverId == null) {
            return false;
        }
        if (ELEVATED_ROLES.stream().anyMatch(securityContext::isUserInRole)) {
            return true;
        }
        if (!securityContext.isUserInRole("USER")) {
            return false;
        }
        UserProfileResponse profile = authWsService.getCurrentUserProfile(securityContext.getUserPrincipal().getName());
        return Objects.equals(profile.getDriverId(), driverId);
    }
}