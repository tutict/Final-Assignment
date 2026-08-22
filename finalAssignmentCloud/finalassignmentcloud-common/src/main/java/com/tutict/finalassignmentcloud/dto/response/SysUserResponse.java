package com.tutict.finalassignmentcloud.dto.response;

import com.tutict.finalassignmentcloud.entity.SysUser;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Safe DTO for user information exposed to external APIs.
 * Password, salt, idCardNumber, contactNumber, loginFailures, lastLoginIp,
 * and passwordUpdateTime are never included in user-visible responses.
 */
@Data
public class SysUserResponse {

    private Long userId;
    private String username;
    private String realName;
    private String gender;
    private String email;
    private String department;
    private String position;
    private String employeeNumber;
    private String status;
    private LocalDate accountExpiryDate;
    private LocalDateTime lastLoginTime;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;
    private String updatedBy;
    private String remarks;

    public static SysUserResponse fromEntity(SysUser user) {
        if (user == null) {
            return null;
        }
        SysUserResponse response = new SysUserResponse();
        response.setUserId(user.getUserId());
        response.setUsername(user.getUsername());
        response.setRealName(user.getRealName());
        response.setGender(user.getGender());
        response.setEmail(user.getEmail());
        response.setDepartment(user.getDepartment());
        response.setPosition(user.getPosition());
        response.setEmployeeNumber(user.getEmployeeNumber());
        response.setStatus(user.getStatus());
        response.setAccountExpiryDate(user.getAccountExpiryDate());
        response.setLastLoginTime(user.getLastLoginTime());
        response.setCreatedAt(user.getCreatedAt());
        response.setUpdatedAt(user.getUpdatedAt());
        response.setCreatedBy(user.getCreatedBy());
        response.setUpdatedBy(user.getUpdatedBy());
        response.setRemarks(user.getRemarks());
        return response;
    }
}