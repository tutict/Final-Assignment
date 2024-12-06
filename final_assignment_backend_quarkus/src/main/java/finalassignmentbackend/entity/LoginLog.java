package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 登录日志实体类
 * 该类用于映射数据库中的登录日志表，记录用户登录的相关信息
 */
@Data
@TableName("login_log")
public class LoginLog implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 日志ID，主键，自增
     */
    @TableId(value = "log_id", type = IdType.AUTO)
    private Integer logId;

    /**
     * 登录用户名
     */
    @TableField("username")
    private String username;

    /**
     * 登录IP地址
     */
    @TableField("login_ip_address")
    private String loginIpAddress;

    /**
     * 登录时间
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @TableField("login_time")
    private LocalDateTime loginTime;

    /**
     * 登录结果
     */
    @TableField("login_result")
    private String loginResult;

    /**
     * 浏览器类型
     */
    @TableField("browser_type")
    private String browserType;

    /**
     * 操作系统版本
     */
    @TableField("os_version")
    private String osVersion;

    /**
     * 备注信息
     */
    @TableField("remarks")
    private String remarks;
}