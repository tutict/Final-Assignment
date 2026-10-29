package finalassignmentbackend.ai.guardrail;

import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.chat.request.ResponseFormat;
import dev.langchain4j.model.ollama.OllamaChatModel;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.time.Duration;

/**
 * 裁判模型工厂：按模型名构建一个独立于对话链路的 Ollama 客户端。
 *
 * <p>裁判必须与生成答案的模型分开配置，不能复用聊天模型审查自己的输出。客户端按
 * {@code model + timeout} 缓存，避免每次校验都重建 HTTP 连接池。
 */
@ApplicationScoped
public class JudgeModelFactory {

    @ConfigProperty(name = "quarkus.langchain4j.ollama.base-url", defaultValue = "http://localhost:11434")
    String baseUrl;

    private volatile ChatModel judge;
    private volatile String judgeModelName;

    public ChatModel create(String modelName, Duration timeout) {
        ChatModel current = judge;
        if (current != null && modelName.equals(judgeModelName)) {
            return current;
        }
        synchronized (this) {
            if (judge == null || !modelName.equals(judgeModelName)) {
                // Judgements are single-shot and must be reproducible: temperature 0 and a
                // small output budget keep the verdict cheap and stable. JSON mode makes the
                // model answer with one object instead of prose around it.
                judge = OllamaChatModel.builder()
                        .baseUrl(baseUrl)
                        .modelName(modelName)
                        .timeout(timeout)
                        .temperature(0.0)
                        .numPredict(96)
                        .maxRetries(0)
                        .responseFormat(ResponseFormat.JSON)
                        .build();
                judgeModelName = modelName;
            }
            return judge;
        }
    }
}
