package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;

/**
 * 系统设置类，用于存储系统级别的配置信息
 * 通过注解实现与数据库表system_settings的映射
 * 实现Serializable接口以支持序列化
 */
@Data
@TableName("system_settings")
public class SystemSettings implements Serializable {
    // 序列化版本标识，用于保证序列化兼容性
    @Serial
    private static final long serialVersionUID = 1L;

    // 系统名称，作为数据库主键字段映射
    @TableId(value = "system_name")
    private String systemName;

    // 系统版本，映射到数据库system_version字段
    @TableField("system_version")
    private String systemVersion;

    // 系统描述，映射到数据库system_description字段
    @TableField("system_description")
    private String systemDescription;

    // 版权信息，映射到数据库copyright_info字段
    @TableField("copyright_info")
    private String copyrightInfo;

    // 存储路径，映射到数据库storage_path字段
    @TableField("storage_path")
    private String storagePath;

    // 登录超时时间，映射到数据库login_timeout字段
    @TableField("login_timeout")
    private Integer loginTimeout;

    // 会话超时时间，映射到数据库session_timeout字段
    @TableField("session_timeout")
    private Integer sessionTimeout;

    // 日期格式，映射到数据库date_format字段
    @TableField("date_format")
    private String dateFormat;

    // 分页大小，映射到数据库page_size字段
    @TableField("page_size")
    private Integer pageSize;

    // SMTP服务器地址，映射到数据库smtp_server字段
    @TableField("smtp_server")
    private String smtpServer;

    // 邮箱账号，映射到数据库email_account字段
    @TableField("email_account")
    private String emailAccount;

    // 邮箱密码，映射到数据库email_password字段
    @TableField("email_password")
    private String emailPassword;

    // 备注信息，映射到数据库remarks字段
    @TableField("remarks")
    private String remarks;
}
