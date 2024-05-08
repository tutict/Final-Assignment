package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("fine_information")
public class FineInformation implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    @TableId(value = "offense_id", type = IdType.AUTO)
    private Integer offenseId;

    @TableField("fine_amount")
    private BigDecimal fineAmount;

    @TableField("fine_time")
    private LocalDateTime fineTime;

    @TableField("payee")
    private String payee;

    @TableField("account_number")
    private String accountNumber;

    @TableField("bank")
    private String bank;

    @TableField("receipt_number")
    private String receiptNumber;

    @TableField("remarks")
    private String remarks;
}