package com.tutict.finalassignmentcloud.auth.client;

import com.tutict.finalassignmentcloud.dto.internal.InternalUserCreateRequest;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserProfile;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserView;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.entity.SysUserRole;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.List;

/**
 * 登录所需的密码哈希通过内部 DTO 传递（SysUser 的 password 标记为 WRITE_ONLY，普通响应不会出站）。
 * service token（X-Internal-Service-Token）由全局 feign 拦截器注入，方法签名不再携带该参数。
 *
 * <p>登录/注册流程在拿到终端用户 JWT 之前就要读取用户与角色，因此这些调用一律走
 * {@code /api/users/internal/**}：该路径由服务端校验内部令牌并以内部服务身份执行，
 * 不依赖管理员角色，也不受终端用户角色限制。只有密码校验场景才取用含密码哈希的视图。
 */
@FeignClient(name = "finalassignmentcloud-user")
public interface UserClient {

    @GetMapping("/api/users/internal/authentication/username/{username}")
    InternalUserView getAuthenticationView(@PathVariable("username") String username);

    @GetMapping("/api/users")
    List<SysUser> getAllUsers();

    @PostMapping("/api/users/internal")
    InternalUserProfile createUser(@RequestBody InternalUserCreateRequest request);

    @GetMapping("/api/users/internal/{userId}")
    InternalUserProfile getById(@PathVariable("userId") Long userId);

    @GetMapping("/api/users/internal/{userId}/roles")
    List<SysUserRole> listUserRoles(@PathVariable("userId") Long userId);

    @PostMapping("/api/users/internal/{userId}/roles")
    SysUserRole addUserRole(@PathVariable("userId") Long userId,
                            @RequestBody SysUserRole relation);
}
