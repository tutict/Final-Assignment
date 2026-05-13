package com.tutict.finalassignmentbackend.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class UserResponse {

    private Long userId;
    private String username;
    private String email;
    private String phoneNumber;
    private String roleName;
    private String realName;
    private String gender;
    private String department;
    private String position;
    private String employeeNumber;
    private String status;
    private LocalDateTime createTime;
}
