package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("permission_management")
public class PermissionManagement implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "permission_id", type = IdType.AUTO)
    private Integer permissionId;

    @TableField("permission_name")
    private String permissionName;

    @TableField("permission_description")
    private String permissionDescription;

    @TableField("created_time")
    private LocalDateTime createdTime;

    @TableField("modified_time")
    private LocalDateTime modifiedTime;

    @TableField("remarks")
    private String remarks;
}