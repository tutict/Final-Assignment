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
@TableName("role_management")
public class RoleManagement implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "role_id", type = IdType.AUTO)
    private Integer roleId;

    @TableField("role_name")
    private String roleName;

    @TableField("role_description")
    private String roleDescription;

    @TableField("permission_list")
    private String permissionList;

    @TableField("created_time")
    private LocalDateTime createdTime;

    @TableField("modified_time")
    private LocalDateTime modifiedTime;

    @TableField("remarks")
    private String remarks;
}