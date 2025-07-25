package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("request_history")
public class RequestHistory implements Serializable {

    @Serial
    private static final long serialVersionUID = 0L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("idempotency_key")
    private String idempotentKey;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @TableField("create_time")
    private LocalDateTime createTime;

    @TableField("business_status")
    private String businessStatus;

    @TableField("business_id")
    private Long businessId;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}
