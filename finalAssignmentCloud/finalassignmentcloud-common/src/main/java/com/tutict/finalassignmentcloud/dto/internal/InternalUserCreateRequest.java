package com.tutict.finalassignmentcloud.dto.internal;

import com.tutict.finalassignmentcloud.entity.SysUser;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 内部建号请求。密码字段承载 auth-service 已编码的哈希，不能用于对外接口。
 */
@Data
public class InternalUserCreateRequest {

    private String username;
    private String password;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public SysUser toEntity() {
        SysUser user = new SysUser();
        user.setUsername(username);
        user.setPassword(password);
        user.setSalt(null);
        user.setStatus(status);
        user.setCreatedAt(createdAt);
        user.setUpdatedAt(updatedAt);
        return user;
    }
}
