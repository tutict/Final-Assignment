package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("operation_log")
public class OperationLog {

    private int logId;
    private int userId;
    private Date operationTime;
    private String operationIpAddress;
    private String operationContent;
    private String operationResult;
    private String remarks;
}
