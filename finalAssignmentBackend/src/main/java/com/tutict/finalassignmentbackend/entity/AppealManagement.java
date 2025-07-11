package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("appeal_management")
public class AppealManagement implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;


    @TableId(value = "appeal_id", type = IdType.AUTO)
    private Integer appealId;

    @TableField("offense_id")
    @JsonProperty("offenseId") // Map both field names
    private Integer offenseId;

    @TableField("appellant_name")
    @JsonProperty("appellant_name")
    private String appellantName;

    @TableField("id_card_number")
    @JsonProperty("id_card_number")
    private String idCardNumber;

    @TableField("contact_number")
    @JsonProperty("contact_number")
    private String contactNumber;

    @TableField("appeal_reason")
    @JsonProperty("appeal_reason")
    private String appealReason;

    @TableField("appeal_time")
    @JsonProperty("appeal_time")
    private LocalDateTime appealTime;

    @TableField("process_status")
    @JsonProperty("process_status")
    private String processStatus;

    @TableField("process_result")
    @JsonProperty("process_result")
    private String processResult;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}