package com.tutict.finalassignmentbackend.ai.agent;

import com.tutict.finalassignmentbackend.model.ai.ChatAction;

import java.util.List;
import java.util.Map;

public record AgentToolResult(
        boolean ok,
        String kind,
        String summary,
        Map<String, Object> data,
        List<Map<String, Object>> items,
        ChatAction navigate,
        AgentDraft draft
) {
    public static final String KIND_RESULT = "result";
    public static final String KIND_DRAFT = "draft";
    public static final String KIND_ERROR = "error";
    public static final String KIND_ACTION = "action";

    public static AgentToolResult result(String summary, List<Map<String, Object>> items, ChatAction navigate) {
        return new AgentToolResult(true, KIND_RESULT, summary, Map.of(), items == null ? List.of() : items, navigate, null);
    }

    public static AgentToolResult draft(AgentDraft draft) {
        return new AgentToolResult(true, KIND_DRAFT, draft.summary(), draft.preview(), List.of(), null, draft);
    }

    public static AgentToolResult action(String summary, ChatAction navigate) {
        return new AgentToolResult(true, KIND_ACTION, summary, Map.of(), List.of(), navigate, null);
    }

    public static AgentToolResult error(String summary) {
        return new AgentToolResult(false, KIND_ERROR, summary, Map.of(), List.of(), null, null);
    }

    public String toModelContent() {
        StringBuilder builder = new StringBuilder();
        builder.append("ok=").append(ok).append("; kind=").append(kind).append("; ");
        builder.append(summary == null ? "" : summary);
        if (items != null && !items.isEmpty()) {
            builder.append(" items=").append(items.size());
        }
        if (draft != null) {
            builder.append(" draftId=").append(draft.draftId()).append(" risk=").append(draft.risk());
        }
        return builder.toString();
    }
}
