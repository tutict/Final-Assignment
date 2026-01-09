package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 请求历史表实体类，对应数据库??"sys_request_history"
 * 用于幂等性控制，防止重复提交
 */
@Data
@TableName("sys_request_history")
public class SysRequestHistory implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 记录 ID，主键，自动增长
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 幂等性键
     */
    @TableField("idempotency_key")
    private String idempotencyKey;

    /**
     * 请求方法
     */
    @TableField("request_method")
    private String requestMethod;

    /**
     * 请求 URL
     */
    @TableField("request_url")
    private String requestUrl;

    /**
     * 请求参数
     */
    @TableField("request_params")
    private String requestParams;

    /**
     * 业务类型
     */
    @TableField("business_type")
    private String businessType;

    /**
     * 业务 ID
     */
    @TableField("business_id")
    private Long businessId;

    /**
     * 业务状??
     */
    @TableField("business_status")
    private String businessStatus;

    /**
     * 用户 ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 请求 IP
     */
    @TableField("request_ip")
    private String requestIp;

    /**
     * 创建时间
     */
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    @TableField(value = "updated_at", fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}
