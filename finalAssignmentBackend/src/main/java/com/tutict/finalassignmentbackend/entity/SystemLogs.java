package com.tutict.finalassignmentbackend.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("system_logs")
public class SystemLogs {

    private int logId;
    private String logType;
    private String logContent;
    private Date operationTime;
    private String operationUser;
    private String operationIpAddress;
    private String remarks;

}
