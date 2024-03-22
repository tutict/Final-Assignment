package com.tutict.finalassignmentbackend.entity.relation;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;

@Data
@TableName("user_role")
public class UserRole implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableField("user_id")
    private Integer userId;

    @TableField("role_id")
    private Integer roleId;
}