package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 违法记录表实体类，对应数据库??"offense_record"
 * 记录交通违法行为的详细信息
 */
@Data
@TableName("offense_record")
public class OffenseRecord implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 违法记录 ID，主键，自动增长
     */
    @TableId(value = "offense_id", type = IdType.AUTO)
    private Long offenseId;

    /**
     * 违法代码
     */
    @TableField("offense_code")
    private String offenseCode;

    /**
     * 违法编号 (业务流水??
     */
    @TableField("offense_number")
    private String offenseNumber;

    /**
     * 违法时间
     */
    @TableField("offense_time")
    private LocalDateTime offenseTime;

    /**
     * 违法地点
     */
    @TableField("offense_location")
    private String offenseLocation;

    /**
     * 违法省份
     */
    @TableField("offense_province")
    private String offenseProvince;

    /**
     * 违法城市
     */
    @TableField("offense_city")
    private String offenseCity;

    /**
     * 驾驶??ID
     */
    @TableField("driver_id")
    private Long driverId;

    /**
     * 车辆 ID
     */
    @TableField("vehicle_id")
    private Long vehicleId;

    /**
     * 违法详情描述
     */
    @TableField("offense_description")
    private String offenseDescription;

    /**
     * 证据类型 (Photo, Video, Witness, Sensor, Other)
     */
    @TableField("evidence_type")
    private String evidenceType;

    /**
     * 证据文件 URL 列表 (JSON数组)
     */
    @TableField("evidence_urls")
    private String evidenceUrls;

    /**
     * 执法机关
     */
    @TableField("enforcement_agency")
    private String enforcementAgency;

    /**
     * 执法人员
     */
    @TableField("enforcement_officer")
    private String enforcementOfficer;

    /**
     * 执法设备编号
     */
    @TableField("enforcement_device")
    private String enforcementDevice;

    /**
     * 处理状??(Unprocessed, Processing, Processed, Appealing, Appeal_Approved, Appeal_Rejected, Cancelled)
     */
    @TableField("process_status")
    private String processStatus;

    /**
     * 通知状??(Not_Sent, Sent, Received, Confirmed)
     */
    @TableField("notification_status")
    private String notificationStatus;

    /**
     * 通知时间
     */
    @TableField("notification_time")
    private LocalDateTime notificationTime;

    /**
     * 罚款金额 (??
     */
    @TableField("fine_amount")
    private BigDecimal fineAmount;

    /**
     * 扣分
     */
    @TableField("deducted_points")
    private Integer deductedPoints;

    /**
     * 拘留天数
     */
    @TableField("detention_days")
    private Integer detentionDays;

    /**
     * 处理时间
     */
    @TableField("process_time")
    private LocalDateTime processTime;

    /**
     * 处理??
     */
    @TableField("process_handler")
    private String processHandler;

    /**
     * 处理结果
     */
    @TableField("process_result")
    private String processResult;

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
     * 创建??
     */
    @TableField("created_by")
    private String createdBy;

    /**
     * 更新??
     */
    @TableField("updated_by")
    private String updatedBy;

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
