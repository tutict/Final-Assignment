package finalassignmentbackend.controller.ai;

import com.alibaba.dashscope.aigc.generation.Generation;
import com.alibaba.dashscope.aigc.generation.GenerationParam;
import com.alibaba.dashscope.aigc.generation.GenerationResult;
import com.alibaba.dashscope.common.Message;
import com.alibaba.dashscope.common.Role;
import com.alibaba.dashscope.exception.ApiException;
import com.alibaba.dashscope.exception.InputRequiredException;
import com.alibaba.dashscope.exception.NoApiKeyException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.Arrays;
import java.lang.System;

@Path("/ai")
@Produces(MediaType.APPLICATION_JSON)
@Tag(name = "AI Chat", description = "Chat Controller for AI interactions")
public class ChatController {

    // 调用AI接口生成结果
    public static GenerationResult callWithMessage() throws ApiException, NoApiKeyException, InputRequiredException {
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
                // 获取环境变量中的API Key
                .apiKey(System.getenv("DASHSCOPE_API_KEY"))
                // 设置模型为 qwen-plus
                .model("qwen-plus")
                // 设置消息列表
                .messages(Arrays.asList(systemMsg, userMsg))
                .resultFormat(GenerationParam.ResultFormat.MESSAGE)
                .build();
        return gen.call(param);  // 执行AI生成调用
    }

    // 为AI聊天提供RESTful接口
    @GET
    @Path("/chat")
    public Response getChatResponse() {
        try {
            // 调用 AI 生成方法
            GenerationResult result = callWithMessage();
            // 返回AI响应内容
            String aiResponse = result.getOutput().getChoices().getFirst().getMessage().getContent();

            // 返回 HTTP 200 OK 状态以及 AI 响应
            return Response.ok(aiResponse).build();
        } catch (ApiException | NoApiKeyException | InputRequiredException e) {
            // 捕获异常，返回HTTP 400 Bad Request并提供错误信息
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Error: " + e.getMessage() + ". Please refer to the documentation for error codes.")
                    .build();
        }
    }
}
