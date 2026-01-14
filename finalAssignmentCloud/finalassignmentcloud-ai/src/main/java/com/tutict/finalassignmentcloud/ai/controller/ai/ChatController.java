package com.tutict.finalassignmentcloud.ai.controller.ai;

import com.tutict.finalassignmentcloud.ai.service.ChatAgent;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.tutict.finalassignmentcloud.model.ai.ChatActionResponse;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Chat", description = "AI 交通违法智能助手接口")
public class ChatController {

    private final ChatAgent chatAgent;

    public ChatController(ChatAgent chatAgent) {
        this.chatAgent = chatAgent;
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
        return chatAgent.streamChat(message, massage, webSearch);
    }

    @GetMapping(value = "/chat/actions", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(
            summary = "获取 AI 动作方案",
            description = "返回可执行的页面动作方案（JSON），适合前端二次确认后执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回动作方案"),
            @ApiResponse(responseCode = "400", description = "缺少 message/massage 参数"),
            @ApiResponse(responseCode = "500", description = "服务内部错误")
    })
    public ChatActionResponse chatActions(
            @RequestParam(value = "message", required = false)
            @Parameter(description = "用户输入，推荐使用该参数", example = "帮我打开缴费页面并查询罚款")
            String message,
            @RequestParam(value = "massage", required = false)
            @Parameter(description = "兼容的旧参数，已废弃", deprecated = true)
            String massage,
            @RequestParam(value = "webSearch", defaultValue = "false")
            @Parameter(description = "是否启用联网检索", example = "true")
            boolean webSearch) {
        return chatAgent.chatWithActions(message, massage, webSearch);
    }
}
