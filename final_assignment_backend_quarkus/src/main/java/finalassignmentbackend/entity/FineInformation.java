package finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 罚款信息类
 * 该类用于表示数据库中"fine_information"表的记录，包含罚款的相关信息
 */
@Data
@TableName("fine_information")
public class FineInformation implements Serializable {
    // 用于序列化和反序列化时的版本标识
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "fine_id", type = IdType.AUTO)
    private Integer fineId;

    @TableField("offense_id")
    private Integer offenseId;

    // 罚款金额
    @TableField("fine_amount")
    private BigDecimal fineAmount;

    // 罚款时间
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @TableField("fine_time")
    private LocalDateTime fineTime;

    // 缴费人姓名
    @TableField("payee")
    private String payee;

    // 银行账号
    @TableField("account_number")
    private String accountNumber;

    // 银行名称
    @TableField("bank")
    private String bank;

    // 收据编号
    @TableField("receipt_number")
    private String receiptNumber;

    // 备注信息
    @TableField("remarks")
    private String remarks;

    /**
     * 软删除时间戳
     */
    @TableField("deleted_at")
    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}