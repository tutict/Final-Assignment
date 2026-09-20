package com.tutict.finalassignmentcloud.ai.prompt;

import com.tutict.finalassignmentcloud.ai.chat.context.ContextBuilder;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PromptAssembler {

    private final PromptTemplateService promptTemplateService;
    private final ContextBuilder contextBuilder;

    public PromptAssembler(PromptTemplateService promptTemplateService, ContextBuilder contextBuilder) {
        this.promptTemplateService = promptTemplateService;
        this.contextBuilder = contextBuilder;
    }

    public String assemble(
            String userMessage,
            List<String> conversationWindow,
            List<RagRetrievalResult> retrievalResults,
            String agentConstraints
    ) {
        return promptTemplateService.render(
                userMessage,
                conversationWindow(conversationWindow),
                contextBuilder.build(retrievalResults),
                agentConstraints
        );
    }

    private static String conversationWindow(List<String> conversationWindow) {
        if (conversationWindow == null || conversationWindow.isEmpty()) {
            return "";
        }
        StringBuilder builder = new StringBuilder();
        int index = 1;
        for (String turn : conversationWindow) {
            String normalized = turn == null ? "" : turn.trim().replaceAll("[\\p{Zs}\\t\\r\\n]+", " ");
            if (normalized.isBlank()) {
                continue;
            }
            if (!builder.isEmpty()) {
                builder.append("\n");
            }
            builder.append("[").append(index++).append("] ").append(normalized);
        }
        return builder.toString();
    }
}
