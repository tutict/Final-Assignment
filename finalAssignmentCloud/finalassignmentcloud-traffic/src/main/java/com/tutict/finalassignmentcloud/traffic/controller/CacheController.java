package com.tutict.finalassignmentcloud.traffic.controller;

import jakarta.annotation.security.RolesAllowed;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.cache.CacheManager;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Same contract as the Spring monolith: POST /api/cache/clear returns 204.
 * The Flutter deduction page calls this after a successful list.
 */
@RestController
@RequestMapping("/api/cache")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class CacheController {

    private final ObjectProvider<CacheManager> cacheManagers;

    public CacheController(ObjectProvider<CacheManager> cacheManagers) {
        this.cacheManagers = cacheManagers;
    }

    @PostMapping("/clear")
    public ResponseEntity<Void> clear() {
        cacheManagers.ifAvailable(manager -> {
            for (String name : manager.getCacheNames()) {
                var cache = manager.getCache(name);
                if (cache != null) {
                    cache.clear();
                }
            }
        });
        return ResponseEntity.noContent().build();
    }
}
