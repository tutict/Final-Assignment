package com.tutict.finalassignmentbackend.dto.response;

import com.tutict.finalassignmentbackend.entity.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.AuditOperationLog;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class LogOverviewResponse {
    private long loginLogCount;
    private long operationLogCount;
    private long requestHistoryCount;
    private List<AuditLoginLog> recentLoginLogs;
    private List<AuditOperationLog> recentOperationLogs;
    private List<SysRequestHistory> recentRequestHistories;
}
