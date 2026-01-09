package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 罚款记录表实体类，对应数据库??"fine_record"
 * 记录违法行为对应的罚款信??
 */
@Data
@TableName("fine_record")
public class FineRecord implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 罚款记录 ID，主键，自动增长
     */
    @TableId(value = "fine_id", type = IdType.AUTO)
    private Long fineId;

    /**
     * 违法记录 ID
     */
    @TableField("offense_id")
    private Long offenseId;

    /**
     * 罚款编号 (决定书编??
     */
    @TableField("fine_number")
    private String fineNumber;

    /**
     * 罚款金额 (??
     */
    @TableField("fine_amount")
    private BigDecimal fineAmount;

    /**
     * 滞纳??(??
     */
    @TableField("late_fee")
    private BigDecimal lateFee;

    /**
     * 总金??(??
     */
    @TableField("total_amount")
    private BigDecimal totalAmount;

    /**
     * 罚款决定日期
     */
    @TableField("fine_date")
    private LocalDate fineDate;

    /**
     * 缴款期限
     */
    @TableField("payment_deadline")
    private LocalDate paymentDeadline;

    /**
     * 开具机??
     */
    @TableField("issuing_authority")
    private String issuingAuthority;

    /**
     * 经办??
     */
    @TableField("handler")
    private String handler;

    /**
     * 审批??
     */
    @TableField("approver")
    private String approver;

    /**
     * 支付状??(Unpaid, Partial, Paid, Overdue, Waived)
     */
    @TableField("payment_status")
    private String paymentStatus;

    /**
     * 已支付金??(??
     */
    @TableField("paid_amount")
    private BigDecimal paidAmount;

    /**
     * 未支付金??(??
     */
    @TableField("unpaid_amount")
    private BigDecimal unpaidAmount;

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
