package finalassignmentbackend.controller;

import io.quarkus.cache.Cache;
import io.quarkus.cache.CacheManager;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

import java.time.Duration;

/**
 * Flutter deduction pages call POST /api/cache/clear after loading records.
 */
@Path("/api/cache")
public class CacheResource {

    @Inject
    CacheManager cacheManager;

    @POST
    @Path("/clear")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
    public Response clear() {
        if (cacheManager != null) {
            for (String name : cacheManager.getCacheNames()) {
                cacheManager.getCache(name).ifPresent(CacheResource::invalidate);
            }
        }
        return Response.noContent().build();
    }

    private static void invalidate(Cache cache) {
        cache.invalidateAll().await().atMost(Duration.ofSeconds(2));
    }
}
