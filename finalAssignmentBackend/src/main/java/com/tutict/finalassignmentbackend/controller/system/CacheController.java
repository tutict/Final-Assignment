package com.tutict.finalassignmentbackend.controller.system;

import jakarta.annotation.security.RolesAllowed;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.CacheManager;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Flutter 扣分页在加载后会调用此接口刷新缓存。
 * 接口缺失时客户端把 404 当成空列表，已加载的记录会被清掉。
 */
@RestController
@RequestMapping("/api/cache")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class CacheController {

    private final CacheManager cacheManager;

    public CacheController(@Autowired(required = false) CacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    @PostMapping("/clear")
    public ResponseEntity<Void> clear() {
        if (cacheManager != null) {
            for (String name : cacheManager.getCacheNames()) {
                var cache = cacheManager.getCache(name);
                if (cache != null) {
                    cache.clear();
                }
            }
        }
        return ResponseEntity.noContent().build();
    }
}
