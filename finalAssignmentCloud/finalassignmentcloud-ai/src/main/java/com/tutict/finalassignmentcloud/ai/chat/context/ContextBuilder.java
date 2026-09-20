package com.tutict.finalassignmentcloud.ai.chat.context;

import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ContextBuilder {

    private final int tokenBudget;

    public ContextBuilder() {
        this(1200);
    }

    public ContextBuilder(int tokenBudget) {
        this.tokenBudget = Math.max(200, tokenBudget);
    }

    public String build(List<RagRetrievalResult> results) {
        if (results == null || results.isEmpty()) {
            return "<retrieved_context>\n</retrieved_context>";
        }
        StringBuilder builder = new StringBuilder("<retrieved_context>\n");
        int used = 0;
        int index = 1;
        for (RagRetrievalResult result : results) {
            String title = result.title() == null ? "Untitled" : result.title();
            String content = result.content() == null ? "" : result.content();
            String block = index + ". " + title + "\n" + content + "\n";
            if (used + block.length() > tokenBudget * 4) {
                break;
            }
            builder.append(block);
            used += block.length();
            index++;
        }
        builder.append("</retrieved_context>");
        return builder.toString();
    }
}
