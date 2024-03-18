package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("appeal_management")
public class AppealManagement {

    private int offenseId;
    private String appellantName;
    private String idCardNumber;
    private String contactNumber;
    private String appealReason;
    private Date appealTime;
    private String processStatus;
    private String processResult;
}
