package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 扣分记录表实体类，对应数据库??"deduction_record"
 * 记录驾驶员的扣分信息
 */
@Data
@TableName("deduction_record")
public class DeductionRecord implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 扣分记录 ID，主键，自动增长
     */
    @TableId(value = "deduction_id", type = IdType.AUTO)
    private Long deductionId;

    /**
     * 违法记录 ID
     */
    @TableField("offense_id")
    private Long offenseId;

    /**
     * 驾驶??ID
     */
    @TableField("driver_id")
    private Long driverId;

    /**
     * 扣分分??
     */
    @TableField("deducted_points")
    private Integer deductedPoints;

    /**
     * 扣分时间
     */
    @TableField("deduction_time")
    private LocalDateTime deductionTime;

    /**
     * 记分周期 (?? 2025-01-01??026-01-01)
     */
    @TableField("scoring_cycle")
    private String scoringCycle;

    /**
     * 处理??
     */
    @TableField("handler")
    private String handler;

    /**
     * 处理部门
     */
    @TableField("handler_dept")
    private String handlerDept;

    /**
     * 审批??
     */
    @TableField("approver")
    private String approver;

    /**
     * 审批时间
     */
    @TableField("approval_time")
    private LocalDateTime approvalTime;

    /**
     * 状??(Effective, Cancelled, Restored)
     */
    @TableField("status")
    private String status;

    /**
     * 恢复时间
     */
    @TableField("restore_time")
    private LocalDateTime restoreTime;

    /**
     * 恢复原因
     */
    @TableField("restore_reason")
    private String restoreReason;

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
