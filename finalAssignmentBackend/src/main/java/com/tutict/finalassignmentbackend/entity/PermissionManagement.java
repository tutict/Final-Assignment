package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("permission_management")
public class PermissionManagement {

    private int permissionId;
    private String permissionName;
    private String permissionDescription;
    private Date createdTime;
    private Date modifiedTime;
    private String remarks;
}
