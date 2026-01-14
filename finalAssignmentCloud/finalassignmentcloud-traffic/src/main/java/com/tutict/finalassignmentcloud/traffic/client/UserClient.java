package com.tutict.finalassignmentcloud.traffic.client;

import com.tutict.finalassignmentcloud.entity.SysUser;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

@FeignClient(name = "finalassignmentcloud-user")
public interface UserClient {

    @GetMapping("/api/users/{userId}")
    SysUser getById(@PathVariable("userId") Long userId);

    @PutMapping("/api/users/{userId}")
    SysUser update(@PathVariable("userId") Long userId,
                   @RequestBody SysUser request,
                   @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);
}
