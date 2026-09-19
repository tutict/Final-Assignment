package finalassignmentbackend.controller;

import finalassignmentbackend.dto.UserProfileResponse;
import finalassignmentbackend.service.AuthWsService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;

@ApplicationScoped
public class DriverAccessGuard {
    public static final Set<String> ELEVATED_ROLES = Set.of(
            "SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER");

    @Inject
    AuthWsService authWsService;

    public DriverAccessGuard() {
    }

    DriverAccessGuard(AuthWsService authWsService) {
        this.authWsService = authWsService;
    }

    public boolean isElevated(SecurityContext securityContext) {
        if (securityContext == null || securityContext.getUserPrincipal() == null) {
            return false;
        }
        return ELEVATED_ROLES.stream().anyMatch(securityContext::isUserInRole);
    }

    public Long currentDriverId(SecurityContext securityContext) {
        if (securityContext == null || securityContext.getUserPrincipal() == null) {
            return null;
        }
        UserProfileResponse profile = authWsService.getCurrentUserProfile(securityContext.getUserPrincipal().getName());
        return profile == null ? null : profile.getDriverId();
    }

    public boolean canAccessDriver(SecurityContext securityContext, Long driverId) {
        if (driverId == null) {
            return false;
        }
        if (isElevated(securityContext)) {
            return true;
        }
        if (!securityContext.isUserInRole("USER")) {
            return false;
        }
        return Objects.equals(currentDriverId(securityContext), driverId);
    }

    public <T> List<T> scopedOrEmpty(SecurityContext securityContext, Function<Long, List<T>> byDriver) {
        Long driverId = currentDriverId(securityContext);
        if (driverId == null) {
            return List.of();
        }
        List<T> result = byDriver.apply(driverId);
        return result == null ? List.of() : result;
    }

    public Response forbidden() {
        return Response.status(Response.Status.FORBIDDEN).entity(Map.of("error", "Forbidden")).build();
    }
}