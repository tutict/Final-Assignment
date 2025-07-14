package finalassignmentbackend.controller.ai;

import dev.langchain4j.data.message.AiMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.StreamingResponseHandler;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.output.Response;
import finalassignmentbackend.service.AIChatSearchService;
import io.smallrye.mutiny.Multi;
import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

// Quarkus REST控制器类，用于处理AI聊天请求
@Path("/api/ai")
public class ChatController {

    // 日志记录器，用于记录聊天请求处理过程中的信息
    private static final Logger LOG = Logger.getLogger(ChatController.class.getName());

    // 注入LangChain4j的ChatLanguageModel用于生成聊天响应
    @Inject
    ChatLanguageModel chatModel;

    // 注入AIChatSearchService用于执行网络搜索
    @Inject
    AIChatSearchService aiChatSearchService;

    // 处理聊天请求的端点，支持流式响应
    @GET
    @Path("/chat")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    public Multi<String> chat(
            @QueryParam("message") String message,
            @QueryParam("massage") String massage,
            @QueryParam("webSearch") @DefaultValue("false") boolean webSearch) {

        // 验证和选择用户消息
        String userMessage = (message != null && !message.isBlank())
                ? message
                : (massage != null ? massage : "");
        if (userMessage.isBlank()) {
            throw new IllegalArgumentException("缺少请求参数：message 或 massage 必须提供其一");
        }
        if (massage != null && !massage.isBlank()) {
            LOG.log(Level.WARNING, "使用了已废弃的参数 'massage'，建议使用 'message'");
        }

        LOG.log(Level.INFO, "收到聊天请求: message={0}, webSearch={1}",
                new Object[]{userMessage, webSearch});

        // 系统提示，定义AI助手的角色和输出格式
        String systemPrompt = "你是一个专业的交通违法查询助手。请用简洁、准确的中文回答，" +
                "仅提供结构化输出，如编号列表或要点。";
        StringBuilder promptBuilder = new StringBuilder(systemPrompt).append("\n\n");

        // 如果启用网络搜索，附加搜索结果
        if (webSearch) {
            List<Map<String, String>> results = aiChatSearchService.search(userMessage);
            StringBuilder sb = getStringBuilder(results);
            promptBuilder.append("以下是搜索结果：\n")
                    .append(sb)
                    .append("\n");
        }

        // 附加用户问题
        promptBuilder.append("用户问题：").append(userMessage);
        String finalPrompt = promptBuilder.toString();

        // 创建UserMessage对象
        UserMessage prompt = new UserMessage(finalPrompt);

        // 使用Multi来处理流式响应
        return Multi.createFrom().emitter(emitter -> {
            chatModel.generate(prompt, new StreamingResponseHandler<>() {
                @Override
                public void onNext(String token) {
                    // 每次收到新令牌时发送到客户端
                    emitter.emit(token);
                }

                @Override
                public void onComplete(Response<AiMessage> response) {
                    // 流式响应完成
                    emitter.complete();
                    LOG.log(Level.INFO, "聊天响应流完成: {0}", response.content().text());
                }

                @Override
                public void onError(Throwable error) {
                    // 处理流式响应中的错误
                    emitter.fail(error);
                    LOG.log(Level.SEVERE, "聊天响应流错误: {0}", error.getMessage());
                }
            });
        });
    }

    // 构建搜索结果的字符串表示
    private static StringBuilder getStringBuilder(List<Map<String, String>> results) {
        StringBuilder sb = new StringBuilder();
        if (results.isEmpty()) {
            sb.append("没找到任何相关消息");
        } else {
            for (int i = 0; i < results.size(); i++) {
                Map<String, String> item = results.get(i);
                sb.append(String.format("%d. %s\n   %s\n",
                        i + 1,
                        item.getOrDefault("title", "<无标题>"),
                        item.getOrDefault("abstract", "<无摘要>")));
            }
        }
        return sb;
    }
}