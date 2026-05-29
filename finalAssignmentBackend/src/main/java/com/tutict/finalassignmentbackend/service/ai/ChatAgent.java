package com.tutict.finalassignmentbackend.service.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.prompt.AgentConstraintService;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRoleResolver;
import com.tutict.finalassignmentbackend.model.ai.ChatActionResponse;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

@Service
public class ChatAgent {

    private static final Logger logger = LoggerFactory.getLogger(ChatAgent.class);
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final long CHAT_TIMEOUT_SECONDS = 30;

    private final OllamaChatModel chatModel;
    private final AIChatSearchService aiChatSearchService;
    private final AiAgentRoleResolver aiAgentRoleResolver;
    private final AgentConstraintService agentConstraintService;
    private final ExecutorService aiExecutor = Executors.newFixedThreadPool(
            Math.max(2, Runtime.getRuntime().availableProcessors() / 2)
    );

    public ChatAgent(
            OllamaChatModel chatModel,
            AIChatSearchService aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService
    ) {
        this.chatModel = chatModel;
        this.aiChatSearchService = aiChatSearchService;
        this.aiAgentRoleResolver = aiAgentRoleResolver;
        this.agentConstraintService = agentConstraintService;
    }

    public Flux<ChatResponse> streamChat(String message, String massage, boolean webSearch) {
        String userMessage = resolveUserMessage(message, massage);
        if (massage != null && !massage.isBlank()) {
            logger.warn("Parameter 'massage' has been deprecated, please use 'message' instead.");
        }

        logger.info("AI chat request received. length={}, webSearch={}, traceId={}",
                userMessage.length(), webSearch, MDC.get("traceId"));

        Prompt prompt = buildPrompt(userMessage, webSearch);
        return chatModel.stream(prompt);
    }

    public ChatActionResponse chatWithActions(String message, String massage, boolean webSearch) {
        String userMessage = resolveUserMessage(message, massage);
        if (massage != null && !massage.isBlank()) {
            logger.warn("Parameter 'massage' has been deprecated, please use 'message' instead.");
        }

        logger.info("AI chat actions request received. length={}, webSearch={}, traceId={}",
                userMessage.length(), webSearch, MDC.get("traceId"));

        Prompt prompt = buildActionPrompt(userMessage, webSearch);
        ChatResponse response = callWithTimeout(prompt);
        String content = extractResponseText(response);
        return parseActionResponse(content);
    }

    private ChatResponse callWithTimeout(Prompt prompt) {
        CompletableFuture<ChatResponse> future = CompletableFuture.supplyAsync(
                () -> chatModel.call(prompt),
                aiExecutor);
        try {
            return future.get(CHAT_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        } catch (TimeoutException ex) {
            future.cancel(true);
            throw new IllegalStateException("AI response timed out after " + CHAT_TIMEOUT_SECONDS + " seconds", ex);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("AI response was interrupted", ex);
        } catch (Exception ex) {
            throw new IllegalStateException("AI response failed", ex);
        }
    }

    private Prompt buildPrompt(String userMessage, boolean webSearch) {
        String agentConstraints = currentAgentConstraints();
        StringBuilder promptBuilder = new StringBuilder(
                "你是一名专业的交通违法查询助手，请用简洁准确的中文回答，并尽量使用结构化的编号或要点。"
        ).append("\n\n")
                .append("Agent role policy markdown:\n")
                .append(agentConstraints)
                .append("\n\n");

        if (webSearch) {
            List<Map<String, String>> searchResults = aiChatSearchService.search(userMessage);
            promptBuilder.append("以下是相关的搜索结果：\n")
                    .append(formatSearchResults(searchResults))
                    .append("\n");
        }

        promptBuilder.append("用户问题：").append(userMessage);

        return new Prompt(new UserMessage(promptBuilder.toString()));
    }

    private Prompt buildActionPrompt(String userMessage, boolean webSearch) {
        String agentConstraints = currentAgentConstraints();
        StringBuilder promptBuilder = new StringBuilder(
                "你是一个交通违法业务助手，需要输出可执行的页面动作方案。"
        ).append("\n")
                .append("请严格输出 JSON，不要使用 Markdown，不要输出额外解释。")
                .append("\n\n")
                .append("Agent role policy markdown:\n")
                .append(agentConstraints)
                .append("\n\n");

        if (webSearch) {
            List<Map<String, String>> searchResults = aiChatSearchService.search(userMessage);
            promptBuilder.append("以下是相关的搜索结果：\n")
                    .append(formatSearchResults(searchResults))
                    .append("\n");
        }

        promptBuilder.append("用户问题：").append(userMessage).append("\n\n")
                .append("JSON 格式示例：\n")
                .append("{\n")
                .append("  \"answer\": \"...\",\n")
                .append("  \"actions\": [\n")
                .append("    {\"type\": \"NAVIGATE\", \"label\": \"...\", \"target\": \"/path\", \"value\": \"\"}\n")
                .append("  ],\n")
                .append("  \"needConfirm\": true\n")
                .append("}\n")
                .append("约束：actions.type 仅能取 NAVIGATE / FILL_FORM / CALL_API / SHOW_MODAL。")
                .append("如果无法执行动作，请返回空数组 actions，并将 needConfirm 设为 false。");

        return new Prompt(new UserMessage(promptBuilder.toString()));
    }

    private String resolveUserMessage(String message, String massage) {
        if (message != null && !message.isBlank()) {
            return message.trim();
        }
        if (massage != null && !massage.isBlank()) {
            return massage.trim();
        }
        throw new IllegalArgumentException("缺少请求参数：message 或 massage 至少提供一个。");
    }

    private String currentAgentConstraints() {
        AiAgentRole role = aiAgentRoleResolver.resolve(Map.of());
        return agentConstraintService.constraintsFor(role);
    }

    private String extractResponseText(ChatResponse response) {
        if (response == null || response.getResult() == null || response.getResult().getOutput() == null) {
            return "";
        }
        return response.getResult().getOutput().getText();
    }

    private ChatActionResponse parseActionResponse(String content) {
        String cleaned = stripCodeFence(content).trim();
        String json = extractJsonObject(cleaned);
        if (json == null || json.isBlank()) {
            return fallbackActionResponse(cleaned);
        }
        try {
            ChatActionResponse parsed = OBJECT_MAPPER.readValue(json, ChatActionResponse.class);
            if (parsed.getAnswer() == null || parsed.getAnswer().isBlank()) {
                parsed.setAnswer(cleaned);
            }
            if (parsed.getActions() == null) {
                parsed.setActions(Collections.emptyList());
            }
            return parsed;
        } catch (Exception e) {
            logger.warn("Failed to parse action JSON. raw={}", cleaned, e);
            return fallbackActionResponse(cleaned);
        }
    }

    private ChatActionResponse fallbackActionResponse(String content) {
        String answer = content == null ? "" : content;
        return new ChatActionResponse(answer, Collections.emptyList(), false);
    }

    private String stripCodeFence(String content) {
        if (content == null) {
            return "";
        }
        String trimmed = content.trim();
        if (trimmed.startsWith("```")) {
            int firstLineBreak = trimmed.indexOf('\n');
            if (firstLineBreak != -1) {
                trimmed = trimmed.substring(firstLineBreak + 1);
            }
            int lastFence = trimmed.lastIndexOf("```");
            if (lastFence != -1) {
                trimmed = trimmed.substring(0, lastFence);
            }
        }
        return trimmed.trim();
    }

    private String extractJsonObject(String content) {
        if (content == null) {
            return null;
        }
        int start = content.indexOf('{');
        if (start < 0) {
            return null;
        }
        int depth = 0;
        boolean inString = false;
        boolean escape = false;
        for (int i = start; i < content.length(); i++) {
            char ch = content.charAt(i);
            if (escape) {
                escape = false;
                continue;
            }
            if (ch == '\\' && inString) {
                escape = true;
                continue;
            }
            if (ch == '"') {
                inString = !inString;
            }
            if (!inString) {
                if (ch == '{') {
                    depth++;
                } else if (ch == '}') {
                    depth--;
                    if (depth == 0) {
                        return content.substring(start, i + 1);
                    }
                }
            }
        }
        return null;
    }

    private static StringBuilder formatSearchResults(List<Map<String, String>> results) {
        StringBuilder builder = new StringBuilder();
        if (results.isEmpty()) {
            builder.append("未检索到可用的参考资料。");
        } else {
            for (int i = 0; i < results.size(); i++) {
                Map<String, String> item = results.get(i);
                builder.append(i + 1).append(". ")
                        .append(item.getOrDefault("title", "<无标题>"))
                        .append("\n   ")
                        .append(item.getOrDefault("abstract", "<无摘要>"))
                        .append("\n");
            }
        }
        return builder;
    }

    @PreDestroy
    public void shutdown() {
        aiExecutor.shutdownNow();
    }
}
