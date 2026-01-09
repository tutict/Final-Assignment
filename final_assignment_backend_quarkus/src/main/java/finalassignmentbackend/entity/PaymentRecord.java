package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 支付记录表实体类，对应数据库??"payment_record"
 * 记录罚款的支付明细信??
 */
@Data
@TableName("payment_record")
public class PaymentRecord implements Serializable {
    /**
     * 序列化版??UID
     */
    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 支付记录 ID，主键，自动增长
     */
    @TableId(value = "payment_id", type = IdType.AUTO)
    private Long paymentId;

    /**
     * 罚款记录 ID
     */
    @TableField("fine_id")
    private Long fineId;

    /**
     * 支付流水??
     */
    @TableField("payment_number")
    private String paymentNumber;

    /**
     * 支付金额 (??
     */
    @TableField("payment_amount")
    private BigDecimal paymentAmount;

    /**
     * 支付方式 (Cash, BankCard, Alipay, WeChat, BankTransfer, Other)
     */
    @TableField("payment_method")
    private String paymentMethod;

    /**
     * 支付时间
     */
    @TableField("payment_time")
    private LocalDateTime paymentTime;

    /**
     * 支付渠道
     */
    @TableField("payment_channel")
    private String paymentChannel;

    /**
     * 缴款人姓??
     */
    @TableField("payer_name")
    private String payerName;

    /**
     * 缴款人身份证??
     */
    @TableField("payer_id_card")
    private String payerIdCard;

    /**
     * 缴款人联系电??
     */
    @TableField("payer_contact")
    private String payerContact;

    /**
     * 银行名称
     */
    @TableField("bank_name")
    private String bankName;

    /**
     * 银行账号
     */
    @TableField("bank_account")
    private String bankAccount;

    /**
     * 交易流水??
     */
    @TableField("transaction_id")
    private String transactionId;

    /**
     * 票据号码
     */
    @TableField("receipt_number")
    private String receiptNumber;

    /**
     * 票据文件 URL
     */
    @TableField("receipt_url")
    private String receiptUrl;

    /**
     * 支付状??(Pending, Success, Failed, Refunded, Cancelled)
     */
    @TableField("payment_status")
    private String paymentStatus;

    /**
     * 退款金??(??
     */
    @TableField("refund_amount")
    private BigDecimal refundAmount;

    /**
     * 退款时??
     */
    @TableField("refund_time")
    private LocalDateTime refundTime;

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
