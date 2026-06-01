package com.tutict.finalassignmentcloud.ai.client.rag;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.List;
import java.util.Map;

@FeignClient(name = "finalassignmentcloud-rag")
public interface RagClient {

    @PostMapping("/api/rag/query")
    RagQueryApiResponse query(@RequestBody RagQueryRequest request);

    record RagQueryApiResponse(
            boolean success,
            Map<String, List<RagRetrievalResult>> data,
            String message,
            String errorCode
    ) {
    }
}
