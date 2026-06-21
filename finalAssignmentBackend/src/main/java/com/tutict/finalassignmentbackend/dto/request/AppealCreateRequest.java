package com.tutict.finalassignmentbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AppealCreateRequest {

    @NotNull(message = "违法记录 ID 不能为空")
    private Long offenseId;

    private Long driverId;

    @NotBlank(message = "申诉人姓名不能为空")
    private String appellantName;

    @NotBlank(message = "身份证号不能为空")
    @Pattern(regexp = "^\\d{17}[\\dXx]$", message = "身份证号格式不正确")
    private String idCard;

    @NotBlank(message = "联系方式不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String contact;

    private String appealType = "Other";

    @NotBlank(message = "申诉理由不能为空")
    @Size(min = 10, max = 500, message = "申诉理由 10~500 字")
    private String appealReason;

    @NotNull(message = "申诉时间不能为空")
    private LocalDateTime appealTime;
}
