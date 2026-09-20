package com.tutict.finalassignmentcloud.ai.client.rag;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.Map;

@FeignClient(name = "finalassignmentcloud-rag", contextId = "ragAdminClient")
public interface RagAdminClient {
    @GetMapping("/api/rag/admin/overview")
    Map<String, Object> overview();

    @PostMapping("/api/rag/admin/documents/manual")
    Map<String, Object> createManual(@RequestBody Map<String, Object> body);
}
