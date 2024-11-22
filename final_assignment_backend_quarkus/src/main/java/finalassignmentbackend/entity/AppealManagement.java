package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

// 使用 Lombok 的 @Data 注解自动生成getter/setter、toString、equals和hashCode方法
// @TableName 注解指定了数据表名为"appeal_management"
@Data
@TableName("appeal_management")
public class AppealManagement implements Serializable {
    // 定义序列化ID，用于确保类的版本兼容性
    @Serial
    private static final long serialVersionUID = 1L;

    // 使用@TableId标记主键字段，类型为 AUTO 自增
    @TableId(value = "appeal_id", type = IdType.AUTO)
    private Integer appealId;

    @TableField("offense_id")
    private Integer offenseId;

    // 上诉人姓名，数据库字段名为"appellant_name"
    @TableField("appellant_name")
    private String appellantName;

    // 身份证号码，数据库字段名为"id_card_number"
    @TableField("id_card_number")
    private String idCardNumber;

    // 联系电话，数据库字段名为"contact_number"
    @TableField("contact_number")
    private String contactNumber;

    // 上诉原因，数据库字段名为"appeal_reason"
    @TableField("appeal_reason")
    private String appealReason;

    // 上诉时间，使用LocalDateTime存储，数据库字段名为"appeal_time"
    @TableField("appeal_time")
    private LocalDateTime appealTime;

    // 处理状态，数据库字段名为"process_status"
    @TableField("process_status")
    private String processStatus;

    // 处理结果，数据库字段名为"process_result"
    @TableField("process_result")
    private String processResult;
}
