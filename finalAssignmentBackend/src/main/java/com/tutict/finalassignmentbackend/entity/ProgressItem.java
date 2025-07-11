package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("progress_items") // 指定表名
public class ProgressItem implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO) // 主键，自动递增
    private Integer id;

    @TableField("title") // 映射字段
    private String title;

    @TableField("status") // 映射字段
    private String status; // "Pending", "Processing", "Completed", "Archived"

    @TableField("submit_time")
    private LocalDateTime submitTime;

    @TableField("details") // 映射字段，允许为空
    private String details;

    @TableField("username") // 映射字段
    private String username; // 关联用户

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}