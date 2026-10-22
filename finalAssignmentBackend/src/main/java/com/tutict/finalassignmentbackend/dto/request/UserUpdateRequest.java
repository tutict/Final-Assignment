package com.tutict.finalassignmentbackend.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UserUpdateRequest {

    @Size(min = 3, max = 50, message = "用户名长度 3~50 位")
    private String username;

    @Size(min = 8, max = 100, message = "密码长度 8~100 位")
    private String password;

    @Email(message = "邮箱格式不正确")
    private String email;

    @JsonAlias({"contactNumber", "phone"})
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phoneNumber;

    private String realName;
    private String gender;
    private String department;
    private String position;
    private String employeeNumber;
    private String status;
    private LocalDate accountExpiryDate;
    private String remarks;
}
