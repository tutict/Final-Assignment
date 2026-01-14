package com.tutict.finalassignmentcloud.auth.client;

import com.tutict.finalassignmentcloud.entity.AuditLoginLog;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

@FeignClient(name = "finalassignmentcloud-audit")
public interface AuditLogClient {

    @PostMapping("/api/logs/login")
    AuditLoginLog createLoginLog(@RequestBody AuditLoginLog request,
                                 @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey);
}
