package com.tutict.finalassignmentcloud.ai.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import com.tutict.finalassignmentcloud.ai.prompt.AgentConstraintService;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRoleResolver;
import com.tutict.finalassignmentcloud.ai.reliability.AiFallbackMetrics;
import com.tutict.finalassignmentcloud.ai.reliability.ModelCallBulkhead;
import com.tutict.finalassignmentcloud.model.ai.ChatActionResponse;
import jakarta.annotation.PreDestroy;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.model.Generation;
import org.springframework.beans.factory.annotation.Autowired;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

    private final OllamaChatModel chatModel;
    private final AIChatSearchService aiChatSearchService;
    private final RagRetrievalService ragRetrievalService;
    private static final long CHAT_TIMEOUT_MILLIS = 700;

    private final AiAgentRoleResolver roleResolver;
    private final AgentConstraintService constraintService;
    private final ModelCallBulkhead modelCalls;
    private final AiFallbackMetrics aiFallbackMetrics;
    private final ExecutorService aiExecutor = Executors.newFixedThreadPool(ModelCallBulkhead.MAX_IN_FLIGHT);

    public ChatAgent(OllamaChatModel chatModel,
                     AIChatSearchService aiChatSearchService,
                     RagRetrievalService ragRetrievalService,
                     AiAgentRoleResolver roleResolver,
                     AgentConstraintService constraintService) {
        this(chatModel, aiChatSearchService, ragRetrievalService, roleResolver, constraintService,
                new ModelCallBulkhead(), null);
    }

    @Autowired
    public ChatAgent(OllamaChatModel chatModel,
                     AIChatSearchService aiChatSearchService,
                     RagRetrievalService ragRetrievalService,
                     AiAgentRoleResolver roleResolver,
                     AgentConstraintService constraintService,
                     ModelCallBulkhead modelCalls,
                     AiFallbackMetrics aiFallbackMetrics) {
        this.chatModel = chatModel;
        this.aiChatSearchService = aiChatSearchService;
        this.ragRetrievalService = ragRetrievalService;
        this.roleResolver = roleResolver;
        this.constraintService = constraintService;
        this.modelCalls = modelCalls == null ? new ModelCallBulkhead() : modelCalls;
        this.aiFallbackMetrics = aiFallbackMetrics;
    }

    public Flux<ChatResponse> streamChat(String message, String massage, boolean webSearch) {
        return streamChat(message, massage, webSearch, Map.of());
    }

    public Flux<ChatResponse> streamChat(String message,
                                         String massage,
                                         boolean webSearch,
                                         Map<String, Object> metadata) {
        String userMessage = resolveUserMessage(message, massage);
        if (massage != null && !massage.isBlank()) {
            logger.warn("Parameter 'massage' has been deprecated, please use 'message' instead.");
        }

        logger.info("AI chat request received. message={}, webSearch={}", userMessage, webSearch);

        Prompt prompt = buildPrompt(userMessage, webSearch, safeMetadata(metadata));
        return Flux.defer(() -> {
            if (!modelCalls.tryAcquire()) {
                markFallback();
                return Flux.just(fallbackChatResponse());
            }
            return chatModel.stream(prompt).doFinally(signal -> modelCalls.release());
        });
    }

    public ChatActionResponse chatWithActions(String message, String massage, boolean webSearch) {
        return chatWithActions(message, massage, webSearch, Map.of());
    }

    public ChatActionResponse chatWithActions(String message,
                                              String massage,
                                              boolean webSearch,
                                              Map<String, Object> metadata) {
        String userMessage = resolveUserMessage(message, massage);
        if (massage != null && !massage.isBlank()) {
            logger.warn("Parameter 'massage' has been deprecated, please use 'message' instead.");
        }

        logger.info("AI chat actions request received. message={}, webSearch={}", userMessage, webSearch);

        Prompt prompt = buildActionPrompt(userMessage, webSearch, safeMetadata(metadata));
        ChatResponse response = completeWithTimeout(prompt);
        if (response == null) {
            return fallbackActions("empty_provider_response");
        }
        String content = extractResponseText(response);
        return parseActionResponse(content);
    }

    private ChatResponse completeWithTimeout(Prompt prompt) {
        if (!modelCalls.tryAcquire()) {
            return null;
        }
        final CompletableFuture<ChatResponse> future;
        try {
            future = CompletableFuture.supplyAsync(() -> {
                try {
                    return chatModel.call(prompt);
                } finally {
                    modelCalls.release();
                }
            }, aiExecutor);
        } catch (RuntimeException ex) {
            modelCalls.release();
            logger.warn("AI action generation was rejected. reason={}", ex.toString());
            return null;
        }
        try {
            return future.get(CHAT_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS);
        } catch (TimeoutException ex) {
            future.cancel(true);
            logger.warn("AI action generation timed out after {} ms", CHAT_TIMEOUT_MILLIS);
            return null;
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            future.cancel(true);
            return null;
        } catch (Exception ex) {
            logger.warn("AI action generation failed. reason={}", ex.toString());
            return null;
        }
    }

    private ChatActionResponse fallbackActions(String reason) {
        markFallback();
        ChatActionResponse response = new ChatActionResponse(
                "AI 动作生成暂时不可用，请先手动操作。",
                List.of(),
                false
        );
        response.setFallback(true);
        logger.info("AI chat actions degraded. reason={}", reason);
        return response;
    }

    private void markFallback() {
        if (aiFallbackMetrics != null) {
            aiFallbackMetrics.increment();
        }
    }

    private ChatResponse fallbackChatResponse() {
        return new ChatResponse(List.of(new Generation(new AssistantMessage("AI 暂时不可用，请稍后再试。"))));
    }

    @PreDestroy
    public void shutdownAiExecutor() {
        aiExecutor.shutdownNow();
    }

    private Prompt buildPrompt(String userMessage, boolean webSearch, Map<String, Object> metadata) {
        AiAgentRole role = roleResolver.resolve(metadata);
        String constraints = constraintService.constraintsFor(role);

        StringBuilder promptBuilder = new StringBuilder()
                .append("你是一名专业的交通违法查询助手，请用简洁准确的中文回答，并尽量使用结构化的编号或要点。")
                .append("\n\n")
                .append("# 权限约束\n")
                .append(constraints)
                .append("\n\n");

        if (webSearch) {
            List<Map<String, String>> searchResults = aiChatSearchService.search(userMessage);
            promptBuilder.append("以下是相关的搜索结果：\n")
                    .append(formatSearchResults(searchResults))
                    .append("\n");
        }

        promptBuilder.append("用户问题：").append(userMessage);

        appendRagContext(promptBuilder, ragRetrievalService.retrieve(userMessage, metadata));
        return new Prompt(new UserMessage(promptBuilder.toString()));
    }

    private Prompt buildActionPrompt(String userMessage, boolean webSearch, Map<String, Object> metadata) {
        AiAgentRole role = roleResolver.resolve(metadata);
        String constraints = constraintService.constraintsFor(role);

        StringBuilder promptBuilder = new StringBuilder()
                .append("你是一个交通违法业务助手，需要输出可执行的页面动作方案。")
                .append("\n")
                .append("请严格输出 JSON，不要使用 Markdown，不要输出额外解释。")
                .append("\n\n")
                .append("# 权限约束\n")
                .append(constraints)
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
                .append("约束：actions.type 仅能为 NAVIGATE / FILL_FORM / CALL_API / SHOW_MODAL。")
                .append("如果无法执行动作，请返回空数组 actions，并将 needConfirm 设为 false。");

        appendRagContext(promptBuilder, ragRetrievalService.retrieve(userMessage, metadata));
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

    private String extractResponseText(ChatResponse response) {
        if (response == null || response.getResult() == null || response.getResult().getOutput() == null) {
            return "";
        }
        String text = response.getResult().getOutput().getText();
        return text == null ? "" : text;
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

    private void appendRagContext(StringBuilder promptBuilder, List<RagRetrievalResult> results) {
        if (results == null || results.isEmpty()) {
            return;
        }
        promptBuilder.append("\n\nKnowledge base context from the RAG service:\n")
                .append(formatRagResults(results))
                .append("Use this context when it is relevant. Do not expose hidden ACL or metadata details.\n\n");
    }

    private static Map<String, Object> safeMetadata(Map<String, Object> metadata) {
        return metadata == null ? Map.of() : metadata;
    }

    private static StringBuilder formatRagResults(List<RagRetrievalResult> results) {
        StringBuilder builder = new StringBuilder();
        int limit = Math.min(results.size(), 8);
        for (int i = 0; i < limit; i++) {
            RagRetrievalResult item = results.get(i);
            builder.append(i + 1).append(". ")
                    .append(defaultText(item.title(), item.sourceType()))
                    .append(" [source=")
                    .append(defaultText(item.sourceTable(), item.sourceType()))
                    .append(", score=")
                    .append(item.finalScore())
                    .append("]\n   ")
                    .append(defaultText(item.content(), ""))
                    .append("\n");
        }
        return builder;
    }

    private static String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
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
}
