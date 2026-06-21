package com.tutict.finalassignmentcloud.dto.response;

import com.tutict.finalassignmentcloud.entity.SysUser;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class SysUserResponse {

    private Long userId;
    private String username;
    private String realName;
    private String idCardNumber;
    private String gender;
    private String contactNumber;
    private String email;
    private String department;
    private String position;
    private String employeeNumber;
    private String status;
    private LocalDate accountExpiryDate;
    private Integer loginFailures;
    private LocalDateTime lastLoginTime;
    private String lastLoginIp;
    private LocalDateTime passwordUpdateTime;
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
        response.setIdCardNumber(maskIdCard(user.getIdCardNumber()));
        response.setGender(user.getGender());
        response.setContactNumber(maskContactNumber(user.getContactNumber()));
        response.setEmail(maskEmail(user.getEmail()));
        response.setDepartment(user.getDepartment());
        response.setPosition(user.getPosition());
        response.setEmployeeNumber(user.getEmployeeNumber());
        response.setStatus(user.getStatus());
        response.setAccountExpiryDate(user.getAccountExpiryDate());
        response.setLoginFailures(user.getLoginFailures());
        response.setLastLoginTime(user.getLastLoginTime());
        response.setLastLoginIp(user.getLastLoginIp());
        response.setPasswordUpdateTime(user.getPasswordUpdateTime());
        response.setCreatedAt(user.getCreatedAt());
        response.setUpdatedAt(user.getUpdatedAt());
        response.setCreatedBy(user.getCreatedBy());
        response.setUpdatedBy(user.getUpdatedBy());
        response.setRemarks(user.getRemarks());
        return response;
    }

    private static String maskIdCard(String value) {
        if (value == null || value.isBlank()) {
            return value;
        }
        if (value.length() < 8) {
            return "***";
        }
        return value.substring(0, 4) + "**********" + value.substring(value.length() - 4);
    }

    private static String maskContactNumber(String value) {
        if (value == null || value.isBlank()) {
            return value;
        }
        if (value.length() < 7) {
            return "***";
        }
        return value.substring(0, 3) + "****" + value.substring(value.length() - 4);
    }

    private static String maskEmail(String value) {
        if (value == null || value.isBlank()) {
            return value;
        }
        int at = value.indexOf('@');
        if (at <= 1) {
            return "***" + (at >= 0 ? value.substring(at) : "");
        }
        return value.charAt(0) + "***" + value.substring(at);
    }
}
