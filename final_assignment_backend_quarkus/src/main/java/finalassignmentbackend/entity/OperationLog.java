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
@TableName("operation_log")
public class OperationLog implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "log_id", type = IdType.AUTO)
    private Integer logId;

    @TableField("user_id")
    private Integer userId;

    @TableField("operation_time")
    private LocalDateTime operationTime;

    @TableField("operation_ip_address")
    private String operationIpAddress;

    @TableField("operation_content")
    private String operationContent;

    @TableField("operation_result")
    private String operationResult;

    @TableField("remarks")
    private String remarks;
}