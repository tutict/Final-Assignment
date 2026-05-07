package com.tutict.finalassignmentbackend.ai.rag.query;

import com.tutict.finalassignmentbackend.ai.chat.AiChatService;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/rag")
public class RagQueryController {

    private final AiChatService aiChatService;

    public RagQueryController(AiChatService aiChatService) {
        this.aiChatService = aiChatService;
    }

    @PostMapping("/query")
    public Map<String, List<RetrievalResult>> query(@RequestBody RagQueryRequest request) {
        return Map.of("results", aiChatService.retrieve(request));
    }
}
