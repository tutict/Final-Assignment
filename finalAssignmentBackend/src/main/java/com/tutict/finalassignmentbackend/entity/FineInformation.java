package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("fine_information")
public class FineInformation {

    private int offenseId;
    private double fineAmount;
    private Date fineTime;
    private String payee;
    private String accountNumber;
    private String bank;
    private String receiptNumber;
    private String remarks;
}
