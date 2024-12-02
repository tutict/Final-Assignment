package com.tutict.finalassignmentbackend.controller.ai;

import com.alibaba.dashscope.aigc.generation.Generation;
import com.alibaba.dashscope.aigc.generation.GenerationParam;
import com.alibaba.dashscope.aigc.generation.GenerationResult;
import com.alibaba.dashscope.common.Message;
import com.alibaba.dashscope.common.Role;
import com.alibaba.dashscope.exception.ApiException;
import com.alibaba.dashscope.exception.InputRequiredException;
import com.alibaba.dashscope.exception.NoApiKeyException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

import java.util.Arrays;

@RestController
@RequestMapping("/ai")
public class ChatController {

    @Value("${DASHSCOPE_API_KEY}")
    private String apiKey;

    // 调用AI接口生成结果
    public GenerationResult callWithMessage() throws ApiException, NoApiKeyException, InputRequiredException {
        Generation gen = new Generation();
        Message systemMsg = Message.builder()
                .role(Role.SYSTEM.getValue())
                .content("You are a helpful assistant.")
                .build();
        Message userMsg = Message.builder()
                .role(Role.USER.getValue())
                .content("你是谁？")
                .build();
        GenerationParam param = GenerationParam.builder()
                .apiKey(apiKey)
                .model("qwen-plus")
                .messages(Arrays.asList(systemMsg, userMsg))
                .resultFormat(GenerationParam.ResultFormat.MESSAGE)
                .build();
        return gen.call(param);  // 执行AI生成调用
    }

    // 为AI聊天提供RESTful接口
    @GetMapping("/chat")
    public ResponseEntity<String> getChatResponse() {
        try {
            // 调用 AI 生成方法
            GenerationResult result = callWithMessage();
            // 返回AI响应内容
            String aiResponse = result.getOutput().getChoices().getFirst().getMessage().getContent();
            // 返回 HTTP 200 OK 状态以及 AI 响应
            return ResponseEntity.ok(aiResponse);
        } catch (ApiException | NoApiKeyException | InputRequiredException e) {
            // 捕获异常，返回HTTP 400 Bad Request并提供错误信息
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Error: " + e.getMessage() + ". Please refer to the documentation for error codes.");
        }
    }
}
