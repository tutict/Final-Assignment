package com.tutict.finalassignmentcloud.auth.client;

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

/**
 * 内部 service-to-service 调用统一返回完整 {@link SysUser}（含 password 哈希），与服务端实际返回一致。
 * service token（X-Internal-Service-Token）由全局 feign 拦截器注入，方法签名不再携带该参数。
 */
@FeignClient(name = "finalassignmentcloud-user")
public interface UserClient {

    @GetMapping("/api/users/internal/search/username/{username}")
    SysUser getByUsername(@PathVariable("username") String username);

    @GetMapping("/api/users")
    List<SysUser> getAllUsers();

    @PostMapping("/api/users")
    SysUser createUser(@RequestBody SysUser request,
                       @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);

    @GetMapping("/api/users/{userId}")
    SysUser getById(@PathVariable("userId") Long userId);

    @PutMapping("/api/users/{userId}")
    SysUser updateUser(@PathVariable("userId") Long userId,
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
