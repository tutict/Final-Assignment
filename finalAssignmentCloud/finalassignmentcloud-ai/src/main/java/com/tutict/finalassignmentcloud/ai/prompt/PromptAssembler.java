package com.tutict.finalassignmentcloud.ai.prompt;

import com.tutict.finalassignmentcloud.ai.rag.dto.RetrievalResult;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PromptAssembler {

    private final PromptTemplateService promptTemplateService;
    private final ContextBuilder contextBuilder;

    public PromptAssembler(
            PromptTemplateService promptTemplateService,
            ContextBuilder contextBuilder
    ) {
        this.promptTemplateService = promptTemplateService;
        this.contextBuilder = contextBuilder;
    }

    public String assemble(
            String userMessage,
            List<String> conversationWindow,
            List<RetrievalResult> retrievalResults
    ) {
        return assemble(userMessage, conversationWindow, retrievalResults, "");
    }

    public String assemble(
            String userMessage,
            List<String> conversationWindow,
            List<RetrievalResult> retrievalResults,
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
            String normalized = normalizeTurn(turn);
            if (normalized.isBlank()) {
                continue;
            }
            if (!builder.isEmpty()) {
                builder.append("\n");
            }
            builder.append("[")
                    .append(index)
                    .append("] ")
                    .append(normalized);
            index++;
        }
        return builder.toString();
    }

    private static String normalizeTurn(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().replaceAll("[\\p{Zs}\\t\\r\\n]+", " ");
    }
}
