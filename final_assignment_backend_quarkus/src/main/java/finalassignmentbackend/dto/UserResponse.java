package finalassignmentbackend.dto;

import finalassignmentbackend.entity.SysUser;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class UserResponse {
    private Long userId;
    private String username;
    private String realName;
    private String email;
    private String contactNumber;
    private String department;
    private String position;
    private String employeeNumber;
    private String status;
    private LocalDateTime lastLoginTime;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static UserResponse from(SysUser user) {
        if (user == null) {
            return null;
        }
        return UserResponse.builder()
                .userId(user.getUserId())
                .username(user.getUsername())
                .realName(user.getRealName())
                .email(user.getEmail())
                .contactNumber(user.getContactNumber())
                .department(user.getDepartment())
                .position(user.getPosition())
                .employeeNumber(user.getEmployeeNumber())
                .status(user.getStatus())
                .lastLoginTime(user.getLastLoginTime())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}