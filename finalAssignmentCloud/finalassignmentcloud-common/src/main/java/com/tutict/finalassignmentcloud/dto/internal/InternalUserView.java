package com.tutict.finalassignmentcloud.dto.internal;

import com.tutict.finalassignmentcloud.entity.SysUser;
import lombok.Data;

/**
 * 仅供内部 service-to-service 调用使用的用户视图，包含登录校验所需的密码哈希。
 * 对外 HTTP 响应一律使用 {@link com.tutict.finalassignmentcloud.dto.response.SysUserResponse}。
 */
@Data
public class InternalUserView {

    private Long userId;
    private String username;
    private String password;
    private String realName;
    private String idCardNumber;
    private String email;
    private String contactNumber;

    public static InternalUserView fromEntity(SysUser user) {
        if (user == null) {
            return null;
        }
        InternalUserView view = new InternalUserView();
        view.setUserId(user.getUserId());
        view.setUsername(user.getUsername());
        view.setPassword(user.getPassword());
        view.setRealName(user.getRealName());
        view.setIdCardNumber(user.getIdCardNumber());
        view.setEmail(user.getEmail());
        view.setContactNumber(user.getContactNumber());
        return view;
    }

    public SysUser toEntity() {
        SysUser user = new SysUser();
        user.setUserId(userId);
        user.setUsername(username);
        user.setPassword(password);
        user.setRealName(realName);
        user.setIdCardNumber(idCardNumber);
        user.setEmail(email);
        user.setContactNumber(contactNumber);
        return user;
    }
}
