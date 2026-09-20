package com.tutict.finalassignmentbackend.ai.agent;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.chat.ChatStreamEvent;
import com.tutict.finalassignmentbackend.ai.chat.ChatStreamEventType;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.ai.provider.AiProviderRegistry;
import com.tutict.finalassignmentbackend.ai.provider.AiToken;
import com.tutict.finalassignmentbackend.model.ai.ChatAction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class AgentRuntime {

    private static final Logger logger = LoggerFactory.getLogger(AgentRuntime.class);
    private static final int DEFAULT_MAX_ROUNDS = 4;

    private final AiProviderRegistry providerRegistry;
    private final AgentToolRegistry toolRegistry;
    private final AgentToolContextFactory contextFactory;
    private final AgentDraftStore draftStore;
    private final AgentIntentRouter intentRouter;
    private final ObjectMapper objectMapper;
    private final int maxRounds;

    public AgentRuntime(
            AiProviderRegistry providerRegistry,
            AgentToolRegistry toolRegistry,
            AgentToolContextFactory contextFactory,
            AgentDraftStore draftStore,
            AgentIntentRouter intentRouter,
            ObjectMapper objectMapper,
            @Value("${ai.agent.max-rounds:4}") int maxRounds
    ) {
        this.providerRegistry = providerRegistry;
        this.toolRegistry = toolRegistry;
        this.contextFactory = contextFactory;
        this.draftStore = draftStore;
        this.intentRouter = intentRouter;
        this.objectMapper = objectMapper;
        this.maxRounds = Math.max(1, Math.min(maxRounds, DEFAULT_MAX_ROUNDS));
    }

    public Flux<ChatStreamEvent> run(String userMessage, String sessionKey, String assembledPrompt) {
        return run(userMessage, sessionKey, assembledPrompt, Map.of());
    }

    public Flux<ChatStreamEvent> run(
            String userMessage,
            String sessionKey,
            String assembledPrompt,
            Map<String, Object> metadata
    ) {
        String effectiveSession = sessionKey == null || sessionKey.isBlank()
                ? UUID.randomUUID().toString()
                : sessionKey;
        String messageId = UUID.randomUUID().toString();
        Map<String, Object> requestMetadata = metadata == null ? Map.of() : metadata;
        AgentToolContext context = contextFactory.create(effectiveSession, requestMetadata);
        AiAgentRole role = context.role();

        List<AgentToolCall> seeded = new ArrayList<>();
        if (intentRouter.isConfirm(userMessage)) {
            Map<String, Object> args = new LinkedHashMap<>();
            String draftId = intentRouter.extractDraftId(userMessage);
            if (draftId == null) {
                draftId = draftStore.lastDraftId(effectiveSession).orElse(null);
            }
            if (draftId != null) {
                args.put("draftId", draftId);
            }
            seeded.add(new AgentToolCall("confirm", "confirm_draft", args));
        } else {
            seeded.addAll(intentRouter.route(userMessage, role));
        }

        List<Map<String, Object>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", assembledPrompt == null ? "" : assembledPrompt));
        messages.add(Map.of("role", "user", "content", userMessage == null ? "" : userMessage));

        Flux<ChatStreamEvent> seedEvents = Flux.empty();
        if (!seeded.isEmpty()) {
            seedEvents = executeCalls(seeded, context, effectiveSession, messageId, messages);
        }

        List<Map<String, Object>> tools = toolRegistry.openAiTools(role);
        return seedEvents.concatWith(Flux.defer(() -> loop(0, messages, tools, context, effectiveSession, messageId)))
                .concatWithValues(ChatStreamEvent.done(effectiveSession, messageId));
    }

    private Flux<ChatStreamEvent> loop(
            int round,
            List<Map<String, Object>> messages,
            List<Map<String, Object>> tools,
            AgentToolContext context,
            String sessionKey,
            String messageId
    ) {
        if (round >= maxRounds) {
            return Flux.just(ChatStreamEvent.token(sessionKey, messageId, "已达到工具调用上限，请补充信息后再试。"));
        }
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("tools", tools);
        metadata.put("messages", messages);
        metadata.put("agentRound", round);
        return providerRegistry.stream(lastUserContent(messages), metadata)
                .collectList()
                .flatMapMany(tokens -> {
                    List<AgentToolCall> calls = extractToolCalls(tokens);
                    if (!calls.isEmpty()) {
                        return executeCalls(calls, context, sessionKey, messageId, messages)
                                .concatWith(Flux.defer(() ->
                                        loop(round + 1, messages, tools, context, sessionKey, messageId)));
                    }
                    return tokenEvents(tokens, sessionKey, messageId);
                });
    }

    private Flux<ChatStreamEvent> executeCalls(
            List<AgentToolCall> calls,
            AgentToolContext context,
            String sessionKey,
            String messageId,
            List<Map<String, Object>> messages
    ) {
        List<ChatStreamEvent> events = new ArrayList<>();
        List<Map<String, Object>> assistantToolCalls = new ArrayList<>();
        List<Map<String, Object>> toolMessages = new ArrayList<>();
        for (AgentToolCall call : calls) {
            events.add(ChatStreamEvent.payload(
                    ChatStreamEventType.TOOL.wireName(),
                    sessionKey,
                    messageId,
                    Map.of("phase", "start", "name", call.name(), "id", call.id())
            ));
            AgentToolResult result = invoke(call, context, sessionKey);
            events.addAll(toEvents(result, sessionKey, messageId, call.name()));
            events.add(ChatStreamEvent.payload(
                    ChatStreamEventType.TOOL.wireName(),
                    sessionKey,
                    messageId,
                    Map.of("phase", "end", "name", call.name(), "id", call.id(), "ok", result.ok())
            ));
            assistantToolCalls.add(Map.of(
                    "id", call.id(),
                    "type", "function",
                    "function", Map.of("name", call.name(), "arguments", writeJson(call.arguments()))
            ));
            toolMessages.add(Map.of(
                    "role", "tool",
                    "tool_call_id", call.id(),
                    "name", call.name(),
                    "content", result.toModelContent()
            ));
        }
        if (!assistantToolCalls.isEmpty()) {
            Map<String, Object> assistant = new LinkedHashMap<>();
            assistant.put("role", "assistant");
            assistant.put("content", "");
            assistant.put("tool_calls", assistantToolCalls);
            messages.add(assistant);
            messages.addAll(toolMessages);
        }
        return Flux.fromIterable(events);
    }

    private AgentToolResult invoke(AgentToolCall call, AgentToolContext context, String sessionKey) {
        var tool = toolRegistry.find(call.name());
        if (tool.isEmpty()) {
            return AgentToolResult.error("未知工具: " + call.name());
        }
        AgentTool agentTool = tool.get();
        if (!agentTool.roles().contains(context.role())) {
            return AgentToolResult.error("当前角色无权使用工具 " + call.name());
        }
        try {
            AgentToolResult result = agentTool.execute(context, call.arguments());
            if (result.draft() != null) {
                draftStore.save(result.draft());
            }
            return result;
        } catch (RuntimeException ex) {
            logger.warn("Agent tool failed. tool={}, reason={}", call.name(), ex.toString());
            return AgentToolResult.error(ex.getMessage() == null ? "工具执行失败" : ex.getMessage());
        }
    }

    private List<ChatStreamEvent> toEvents(AgentToolResult result, String sessionKey, String messageId, String toolName) {
        List<ChatStreamEvent> events = new ArrayList<>();
        if (AgentToolResult.KIND_DRAFT.equals(result.kind()) && result.draft() != null) {
            AgentDraft draft = result.draft();
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("draftId", draft.draftId());
            payload.put("summary", draft.summary());
            payload.put("risk", draft.risk());
            payload.put("serviceName", draft.serviceName());
            payload.put("preview", draft.preview());
            payload.put("expiresAt", draft.expiresAt() == null ? "" : draft.expiresAt().toString());
            events.add(ChatStreamEvent.payload(ChatStreamEventType.DRAFT.wireName(), sessionKey, messageId, payload));
        } else if (AgentToolResult.KIND_ACTION.equals(result.kind()) && result.navigate() != null) {
            events.add(actionEvent(sessionKey, messageId, result.navigate(), result.summary()));
        } else {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("name", toolName);
            payload.put("summary", result.summary());
            payload.put("ok", result.ok());
            payload.put("items", result.items());
            events.add(ChatStreamEvent.payload(ChatStreamEventType.RESULT.wireName(), sessionKey, messageId, payload));
            if (result.navigate() != null) {
                events.add(actionEvent(sessionKey, messageId, result.navigate(), result.summary()));
            }
        }
        return events;
    }

    private static ChatStreamEvent actionEvent(String sessionKey, String messageId, ChatAction action, String summary) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("type", action.getType());
        payload.put("label", action.getLabel());
        payload.put("target", action.getTarget());
        payload.put("value", action.getValue());
        payload.put("summary", summary);
        return ChatStreamEvent.payload(ChatStreamEventType.ACTION.wireName(), sessionKey, messageId, payload);
    }

    private Flux<ChatStreamEvent> tokenEvents(List<AiToken> tokens, String sessionKey, String messageId) {
        List<ChatStreamEvent> events = new ArrayList<>();
        for (AiToken token : tokens) {
            if (token.text() != null && !token.text().isEmpty()) {
                events.add(ChatStreamEvent.token(sessionKey, messageId, token.text()));
            }
        }
        return Flux.fromIterable(events);
    }

    private List<AgentToolCall> extractToolCalls(List<AiToken> tokens) {
        List<AgentToolCall> calls = new ArrayList<>();
        StringBuilder text = new StringBuilder();
        for (AiToken token : tokens) {
            Object raw = token.metadata() == null ? null : token.metadata().get("toolCalls");
            if (raw instanceof List<?> list) {
                for (Object item : list) {
                    AgentToolCall parsed = parseCall(item);
                    if (parsed != null) {
                        calls.add(parsed);
                    }
                }
            }
            if (token.text() != null) {
                text.append(token.text());
            }
        }
        if (calls.isEmpty()) {
            calls.addAll(parseCallsFromText(text.toString()));
        }
        return calls;
    }

    private AgentToolCall parseCall(Object item) {
        if (item instanceof AgentToolCall call) {
            return call;
        }
        if (item instanceof Map<?, ?> map) {
            Object rawName = map.get("name");
            String name = rawName == null ? "" : String.valueOf(rawName);
            if (name.isBlank() && map.get("function") instanceof Map<?, ?> function) {
                Object functionName = function.get("name");
                name = functionName == null ? "" : String.valueOf(functionName);
                Object args = function.get("arguments");
                Object rawId = map.get("id");
                return new AgentToolCall(rawId == null ? "" : String.valueOf(rawId), name, asMap(args));
            }
            Object rawId = map.get("id");
            return new AgentToolCall(rawId == null ? "" : String.valueOf(rawId), name, asMap(map.get("arguments")));
        }
        return null;
    }

    private List<AgentToolCall> parseCallsFromText(String text) {
        String trimmed = text == null ? "" : text.trim();
        if (!trimmed.startsWith("{") || !trimmed.contains("tool")) {
            return List.of();
        }
        try {
            JsonNode node = objectMapper.readTree(trimmed);
            if (node.has("tool_calls")) {
                List<AgentToolCall> calls = new ArrayList<>();
                for (JsonNode call : node.path("tool_calls")) {
                    String name = call.path("name").asText(call.path("function").path("name").asText(""));
                    Map<String, Object> args = asMap(call.path("arguments").isMissingNode()
                            ? call.path("function").path("arguments").asText("{}")
                            : call.get("arguments"));
                    calls.add(new AgentToolCall(call.path("id").asText(""), name, args));
                }
                return calls;
            }
            if (node.has("tool") || node.has("name")) {
                String name = node.path("tool").asText(node.path("name").asText(""));
                return List.of(new AgentToolCall("", name, asMap(node.get("arguments"))));
            }
        } catch (Exception ignored) {
            return List.of();
        }
        return List.of();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> asMap(Object value) {
        if (value == null) {
            return Map.of();
        }
        if (value instanceof Map<?, ?> map) {
            Map<String, Object> copy = new LinkedHashMap<>();
            map.forEach((k, v) -> copy.put(String.valueOf(k), v));
            return copy;
        }
        if (value instanceof JsonNode node) {
            if (node.isTextual()) {
                return asMap(node.asText());
            }
            return objectMapper.convertValue(node, new TypeReference<Map<String, Object>>() {
            });
        }
        String text = value.toString();
        if (text.isBlank()) {
            return Map.of();
        }
        try {
            return objectMapper.readValue(text, new TypeReference<Map<String, Object>>() {
            });
        } catch (Exception ex) {
            return Map.of();
        }
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception ex) {
            return "{}";
        }
    }

    private static String lastUserContent(List<Map<String, Object>> messages) {
        for (int i = messages.size() - 1; i >= 0; i--) {
            Object role = messages.get(i).get("role");
            if ("user".equals(String.valueOf(role))) {
                return String.valueOf(messages.get(i).getOrDefault("content", ""));
            }
        }
        return "";
    }
}
