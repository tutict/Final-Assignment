package com.tutict.finalassignmentcloud.auth.client;

import com.tutict.finalassignmentcloud.entity.SysRole;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

@FeignClient(name = "finalassignmentcloud-user")
public interface RoleClient {

    @GetMapping("/api/roles/{roleId}")
    SysRole getById(@PathVariable("roleId") Long roleId);

    @GetMapping("/api/roles/by-code/{roleCode}")
    SysRole getByCode(@PathVariable("roleCode") String roleCode);

    @PostMapping("/api/roles")
    SysRole create(@RequestBody SysRole role,
                   @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);
}
