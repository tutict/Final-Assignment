package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("role_management")
public class RoleManagement {

    private int roleId;
    private String roleName;
    private String roleDescription;
    private String permissionList;
    private Date createdTime;
    private Date modifiedTime;
    private String remarks;
}
