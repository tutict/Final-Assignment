package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("user_role")
public class UserRole implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableField("user_id")
    private Integer userId;

    @TableField("role_id")
    private Integer roleId;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}