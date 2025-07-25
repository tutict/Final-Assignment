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
@Tag(name = "AI Chat", description = "API for interacting with AI-powered traffic violation query assistant")
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
            summary = "与AI聊天助手交互",
            description = "向AI交通违法查询助手发送消息，支持网络搜索选项，返回结构化的流式响应（Server-Sent Events）。必须提供 `message` 或 `massage` 参数之一，`massage` 已废弃，建议使用 `message`。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回流式聊天响应（SSE 格式）"),
            @ApiResponse(responseCode = "400", description = "缺少必需参数（message 或 massage）或参数无效"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public Flux<ChatResponse> chat(
            @RequestParam(value = "message", required = false) @Parameter(description = "用户消息，推荐使用此参数", example = "如何查询交通违法记录？") String message,
            @RequestParam(value = "massage", required = false) @Parameter(description = "用户消息（已废弃，建议使用 message）", example = "如何查询交通违法记录？", deprecated = true) String massage,
            @RequestParam(value = "webSearch", defaultValue = "false") @Parameter(description = "是否启用网络搜索", example = "true") boolean webSearch) {

        String userMessage = (message != null && !message.isBlank())
                ? message
                : (massage != null ? massage : "");
        if (userMessage.isBlank()) {
            throw new IllegalArgumentException("缺少请求参数：message 或 massage 必须提供其一");
        }
        if (massage != null && !massage.isBlank()) {
            LOG.log(Level.WARNING, "使用了已废弃的参数 'massage'，建议使用 'message'");
        }

        LOG.log(Level.INFO, "Chat request received: message={0}, webSearch={1}",
                new Object[]{userMessage, webSearch});

        String systemPrompt = "你是一个专业的交通违法查询助手。请用简洁、准确的中文回答，" +
                "仅提供结构化输出，如编号列表或要点。";
        StringBuilder promptBuilder = new StringBuilder(systemPrompt).append("\n\n");

        if (webSearch) {
            List<Map<String, String>> results = aiChatSearchService.search(userMessage);
            StringBuilder sb = getStringBuilder(results);
            promptBuilder.append("以下是搜索结果：\n")
                    .append(sb)
                    .append("\n");
        }

        promptBuilder.append("用户问题：").append(userMessage);
        String finalPrompt = promptBuilder.toString();

        Prompt prompt = new Prompt(new UserMessage(finalPrompt));
        return chatModel.stream(prompt);
    }

    private static @NotNull StringBuilder getStringBuilder(List<Map<String, String>> results) {
        StringBuilder sb = new StringBuilder();
        if (results.isEmpty()) {
            sb.append("没找到任何相关消息");
        } else {
            for (int i = 0; i < results.size(); i++) {
                Map<String, String> item = results.get(i);
                sb.append(String.format("%d. %s\n   %s\n",
                        i + 1,
                        item.getOrDefault("title", "<无标题>"),
                        item.getOrDefault("abstract", "<empty abstract>")));
            }
        }
        return sb;
    }
}