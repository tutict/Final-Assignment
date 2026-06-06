package com.tutict.finalassignmentcloud.auth.client;

import com.tutict.finalassignmentcloud.dto.response.SysUserResponse;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.entity.SysUserRole;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(name = "finalassignmentcloud-user")
public interface UserClient {

    @GetMapping("/api/users/internal/search/username/{username}")
    SysUser getByUsername(@PathVariable("username") String username,
                          @RequestHeader("X-Internal-Service-Token") String serviceToken);

    @GetMapping("/api/users")
    List<SysUserResponse> getAllUsers();

    @PostMapping("/api/users")
    SysUserResponse createUser(@RequestBody SysUser request,
                               @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);

    @GetMapping("/api/users/{userId}")
    SysUserResponse getById(@PathVariable("userId") Long userId);

    @PutMapping("/api/users/{userId}")
    SysUserResponse updateUser(@PathVariable("userId") Long userId,
                               @RequestBody SysUser request,
                               @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);

    @GetMapping("/api/users/{userId}/roles")
    List<SysUserRole> listUserRoles(@PathVariable("userId") Long userId,
                                    @RequestParam(value = "page", defaultValue = "1") int page,
                                    @RequestParam(value = "size", defaultValue = "100") int size);

    @PostMapping("/api/users/{userId}/roles")
    SysUserRole addUserRole(@PathVariable("userId") Long userId,
                            @RequestBody SysUserRole relation,
                            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);
}
