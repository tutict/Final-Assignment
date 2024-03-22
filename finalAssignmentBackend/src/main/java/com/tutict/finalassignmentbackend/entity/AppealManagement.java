package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("appeal_management")
public class AppealManagement implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableField("offense_id")
    private Integer offenseId;

    @TableField("appellant_name")
    private String appellantName;

    @TableField("id_card_number")
    private String idCardNumber;

    @TableField("contact_number")
    private String contactNumber;

    @TableField("appeal_reason")
    private String appealReason;

    @TableField("appeal_time")
    private LocalDateTime appealTime;

    @TableField("process_status")
    private String processStatus;

    @TableField("process_result")
    private String processResult;
}