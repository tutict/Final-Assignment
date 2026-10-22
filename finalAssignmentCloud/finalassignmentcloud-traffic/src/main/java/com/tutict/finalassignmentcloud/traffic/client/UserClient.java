package com.tutict.finalassignmentcloud.traffic.client;

import com.tutict.finalassignmentcloud.dto.internal.InternalUserProfile;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;

/**
 * traffic 服务对 user 服务的内部调用：内部档案视图不含密码哈希，
 * 端点由 X-Internal-Service-Token 保护，不依赖管理员角色。
 */
@FeignClient(name = "finalassignmentcloud-user")
public interface UserClient {

    @GetMapping("/api/users/internal/{userId}")
    InternalUserProfile getById(@PathVariable("userId") Long userId);

    @GetMapping("/api/users/internal/profile/username/{username}")
    InternalUserProfile getByUsername(@PathVariable("username") String username);

    @PutMapping("/api/users/internal/{userId}")
    InternalUserProfile update(@PathVariable("userId") Long userId,
                               @RequestBody InternalUserProfile profile);
}
