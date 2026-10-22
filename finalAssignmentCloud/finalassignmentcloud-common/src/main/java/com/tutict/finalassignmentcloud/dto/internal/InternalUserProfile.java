package com.tutict.finalassignmentcloud.dto.internal;

import com.tutict.finalassignmentcloud.entity.SysUser;
import lombok.Data;

/**
 * 内部服务间通用的用户视图：不含密码哈希。
 *
 * <p>仅在确有密码校验需要的认证流程中使用 {@link InternalUserView}；
 * 其余服务间调用一律使用本 DTO，避免密码哈希扩散到 traffic 等无关服务。
 */
@Data
public class InternalUserProfile {

    private Long userId;
    private String username;
    private String realName;
    private String idCardNumber;
    private String email;
    private String contactNumber;

    public static InternalUserProfile fromEntity(SysUser user) {
        if (user == null) {
            return null;
        }
        InternalUserProfile profile = new InternalUserProfile();
        profile.setUserId(user.getUserId());
        profile.setUsername(user.getUsername());
        profile.setRealName(user.getRealName());
        profile.setIdCardNumber(user.getIdCardNumber());
        profile.setEmail(user.getEmail());
        profile.setContactNumber(user.getContactNumber());
        return profile;
    }

    public SysUser toEntity() {
        SysUser user = new SysUser();
        user.setUserId(userId);
        user.setUsername(username);
        user.setRealName(realName);
        user.setIdCardNumber(idCardNumber);
        user.setEmail(email);
        user.setContactNumber(contactNumber);
        return user;
    }
}
