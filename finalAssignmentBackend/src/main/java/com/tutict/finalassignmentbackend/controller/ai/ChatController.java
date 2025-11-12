package com.tutict.finalassignmentbackend.controller.ai;

import com.tutict.finalassignmentbackend.service.AIChatSearchService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.jetbrains.annotations.NotNull;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Chat", description = "AI 交通违法智能助手接口")
public class ChatController {

    private static final Logger LOG = Logger.getLogger(ChatController.class.getName());

    private final OllamaChatModel chatModel;
    private final AIChatSearchService aiChatSearchService;

    public ChatController(OllamaChatModel chatModel, AIChatSearchService aiChatSearchService) {
        this.chatModel = chatModel;
        this.aiChatSearchService = aiChatSearchService;
    }

    @GetMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @Operation(
            summary = "与 AI 交通助手对话",
            description = "发送问题给 AI 交通违法助手，可选开启联网搜索能力，结果以 SSE 流式返回。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回流式响应"),
            @ApiResponse(responseCode = "400", description = "缺少 message/massage 参数"),
            @ApiResponse(responseCode = "500", description = "服务内部错误")
    })
    public Flux<ChatResponse> chat(
            @RequestParam(value = "message", required = false)
            @Parameter(description = "用户输入，推荐使用该参数", example = "如何处理超速罚单？")
            String message,
            @RequestParam(value = "massage", required = false)
            @Parameter(description = "兼容的旧参数，已废弃", deprecated = true)
            String massage,
            @RequestParam(value = "webSearch", defaultValue = "false")
            @Parameter(description = "是否启用联网检索", example = "true")
            boolean webSearch) {

        String userMessage = resolveUserMessage(message, massage);
        if (massage != null && !massage.isBlank()) {
            LOG.log(Level.WARNING, "Parameter 'massage' has been deprecated, please use 'message' instead.");
        }

        LOG.log(Level.INFO, "AI chat request received. message={0}, webSearch={1}",
                new Object[]{userMessage, webSearch});

        StringBuilder promptBuilder = new StringBuilder(
                "你是一名专业的交通违法查询助手，请用简洁准确的中文回答，并尽量使用结构化的编号或要点。"
        ).append("\n\n");

        if (webSearch) {
            List<Map<String, String>> searchResults = aiChatSearchService.search(userMessage);
            promptBuilder.append("以下是相关的搜索结果：\n")
                    .append(formatSearchResults(searchResults))
                    .append("\n");
        }

        promptBuilder.append("用户问题：").append(userMessage);

        Prompt prompt = new Prompt(new UserMessage(promptBuilder.toString()));
        return chatModel.stream(prompt);
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

    private static @NotNull StringBuilder formatSearchResults(List<Map<String, String>> results) {
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

