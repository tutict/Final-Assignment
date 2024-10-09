package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;


/**
 * 角色管理实体类
 * 该类表示数据库中“role_management”表的映射类，用于角色管理相关的数据操作
 */
@Data
@TableName("role_management")
public class RoleManagement implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 角色ID
     * 该字段表示角色的唯一标识符，采用自动增长的方式生成
     */
    @TableId(value = "role_id", type = IdType.AUTO)
    private Integer roleId;

    /**
     * 角色名称
     * 该字段表示角色的名称
     */
    @TableField("role_name")
    private String roleName;

    /**
     * 角色描述
     * 该字段用于描述角色的详细信息
     */
    @TableField("role_description")
    private String roleDescription;

    /**
     * 创建时间
     * 该字段记录角色创建的时间
     */
    @TableField("created_time")
    private LocalDateTime createdTime;

    /**
     * 修改时间
     * 该字段记录角色最后修改的时间
     */
    @TableField("modified_time")
    private LocalDateTime modifiedTime;

    /**
     * 备注
     * 该字段用于记录角色相关的额外信息或备注
     */
    @TableField("remarks")
    private String remarks;

}