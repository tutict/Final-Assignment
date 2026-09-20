package com.tutict.finalassignmentcloud.ai.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Map;

@FeignClient(name = "finalassignmentcloud-audit")
public interface AuditClient {
    @GetMapping("/api/logs/operation")
    List<Map<String, Object>> operations();

    @GetMapping("/api/logs/operation/search/username")
    List<Map<String, Object>> operationsByUsername(@RequestParam("username") String username);

    @GetMapping("/api/logs/login")
    List<Map<String, Object>> logins();

    @GetMapping("/api/logs/login/search/username")
    List<Map<String, Object>> loginsByUsername(@RequestParam("username") String username);
}
