package com.tutict.finalassignmentcloud.auth.client;

import com.tutict.finalassignmentcloud.entity.AuditLoginLog;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

/**
 * 登录日志写入走内部接口：登录失败/成功日志在认证完成前就要落库，此时没有终端用户 JWT。
 */
@FeignClient(name = "finalassignmentcloud-audit")
public interface AuditLogClient {

    @PostMapping("/api/logs/internal/login")
    AuditLoginLog createLoginLog(@RequestBody AuditLoginLog request);
}
