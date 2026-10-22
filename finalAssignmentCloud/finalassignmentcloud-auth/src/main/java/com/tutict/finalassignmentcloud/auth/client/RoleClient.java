package com.tutict.finalassignmentcloud.auth.client;

import com.tutict.finalassignmentcloud.entity.SysRole;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

/**
 * 角色查询与创建走内部接口：登录与注册流程在拿到终端用户 JWT 之前就需要解析角色码。
 */
@FeignClient(name = "finalassignmentcloud-user")
public interface RoleClient {

    @GetMapping("/api/roles/internal/{roleId}")
    SysRole getById(@PathVariable("roleId") Long roleId);

    @GetMapping("/api/roles/internal/by-code/{roleCode}")
    SysRole getByCode(@PathVariable("roleCode") String roleCode);

    @PostMapping("/api/roles/internal")
    SysRole create(@RequestBody SysRole role);
}
