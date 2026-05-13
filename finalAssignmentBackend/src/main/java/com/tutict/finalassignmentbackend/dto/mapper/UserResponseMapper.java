package com.tutict.finalassignmentbackend.dto.mapper;

import com.tutict.finalassignmentbackend.dto.request.UserCreateRequest;
import com.tutict.finalassignmentbackend.dto.response.UserResponse;
import com.tutict.finalassignmentbackend.entity.SysUser;

public final class UserResponseMapper {

    private UserResponseMapper() {
    }

    public static UserResponse toResponse(SysUser user) {
        if (user == null) {
            return null;
        }
        return UserResponse.builder()
                .userId(user.getUserId())
                .username(user.getUsername())
                .email(user.getEmail())
                .phoneNumber(maskPhone(user.getContactNumber()))
                .realName(user.getRealName())
                .gender(user.getGender())
                .department(user.getDepartment())
                .position(user.getPosition())
                .employeeNumber(user.getEmployeeNumber())
                .status(user.getStatus())
                .createTime(user.getCreatedAt())
                .build();
    }

    public static SysUser toEntity(UserCreateRequest request) {
        if (request == null) {
            return null;
        }
        SysUser user = new SysUser();
        user.setUsername(request.getUsername());
        user.setPassword(request.getPassword());
        user.setEmail(request.getEmail());
        user.setContactNumber(request.getPhoneNumber());
        user.setRealName(request.getRealName());
        user.setGender(request.getGender());
        user.setDepartment(request.getDepartment());
        user.setPosition(request.getPosition());
        user.setEmployeeNumber(request.getEmployeeNumber());
        user.setStatus(request.getStatus());
        user.setRemarks(request.getRemarks());
        return user;
    }

    private static String maskPhone(String phone) {
        if (phone == null || phone.length() < 11) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(7);
    }
}
