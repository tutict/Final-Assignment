package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 登录日志表实体类，对应数据库??"audit_login_log"
 * 用于记录系统用户的登录、退出等操作日志
 */
@Data
@TableName("audit_login_log")
public class AuditLoginLog implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 日志 ID，主键，自动增长
     */
    @TableId(value = "log_id", type = IdType.AUTO)
    private Long logId;

    /**
     * 用户??
     */
    @TableField("username")
    private String username;

    /**
     * 登录时间
     */
    @TableField("login_time")
    private LocalDateTime loginTime;

    /**
     * 退出时??
     */
    @TableField("logout_time")
    private LocalDateTime logoutTime;

    /**
     * 登录结果 (Success, Failed, Locked)
     */
    @TableField("login_result")
    private String loginResult;

    /**
     * 失败原因
     */
    @TableField("failure_reason")
    private String failureReason;

    /**
     * 登录 IP
     */
    @TableField("login_ip")
    private String loginIp;

    /**
     * 登录地点
     */
    @TableField("login_location")
    private String loginLocation;

    /**
     * 浏览器类??
     */
    @TableField("browser_type")
    private String browserType;

    /**
     * 浏览器版??
     */
    @TableField("browser_version")
    private String browserVersion;

    /**
     * 操作系统
     */
    @TableField("os_type")
    private String osType;

    /**
     * 操作系统版本
     */
    @TableField("os_version")
    private String osVersion;

    /**
     * 设备类型
     */
    @TableField("device_type")
    private String deviceType;

    /**
     * User Agent
     */
    @TableField("user_agent")
    private String userAgent;

    /**
     * 会话 ID
     */
    @TableField("session_id")
    private String sessionId;

    /**
     * 访问令牌
     */
    @TableField("token")
    private String token;

    /**
     * 创建时间
     */
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;

    /**
     * 备注
     */
    @TableField("remarks")
    private String remarks;
}
