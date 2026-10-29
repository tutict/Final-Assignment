package finalassignmentbackend.ai.guardrail;

import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.chat.request.ChatRequest;
import dev.langchain4j.model.chat.request.ResponseFormat;
import dev.langchain4j.model.chat.response.ChatResponse;
import finalassignmentbackend.rag.service.RagQueryService;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.bind.Jsonb;
import jakarta.json.bind.JsonbBuilder;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 生成后主题校验：判断回答是否仍在回答用户所问的那个业务。
 *
 * <p>引用护栏只能证明"回答里的编号确实指向某段资料"，无法发现模型把问题换成了资料中
 * 另一类业务（例如问报废流程，回答却讲车辆过户）。这里让独立的校验模型同时看问题、
 * 检索资料和草稿回答，只有资料确实覆盖问题主题、且回答围绕该主题时才放行。
 *
 * <p>校验是<b>失败放行</b>的：超时、模型不可用、输出无法解析都不会拦截回答，避免把一次
 * 基础设施故障变成对所有用户的拒答。校验模型必须通过
 * {@code ai.guardrail.topic-verification.model} 显式指定；未配置时校验保持关闭，
 * 因为不应让生成答案的聊天模型审查自己的输出。
 */
@ApplicationScoped
public class TopicGroundingVerifier {

    private static final Logger LOG = Logger.getLogger(TopicGroundingVerifier.class.getName());

    private static final String PROMPT_TEMPLATE = """
            你在审核知识库问答系统的一次回答，只判断主题是否对得上，不评价答案是否完整或正确。

            第一步：问题问的是哪个具体业务或对象？
            第二步：<资料> 中是否有哪一段就是在讲这个业务或对象？如果所有段落讲的都是其他业务，即使内容相关、措辞接近，也判 false。
            第三步：<回答> 是否在讲这个业务？如果回答换成了资料中另一类业务，判 false。
            问题涉及多个事项时，只要资料覆盖其中至少一个事项且回答围绕该事项，就判 true。

            资料：
            %s
            问题：%s
            回答：%s

            输出 JSON：{"topic_in_sources":true或false,"reason":"不超过20字"}""";

    @Inject
    JudgeModelFactory judgeFactory;

    @ConfigProperty(name = "ai.guardrail.topic-verification.enabled", defaultValue = "true")
    boolean enabled;

    /**
     * 判官模型名。
     *
     * <p>用 Optional 而不是带空串默认值的 String：SmallRye 把空字符串按 null 处理，
     * 而 Quarkus 在启动期会拒绝"配置成空串"的 String 属性（SRCFG00040），导致配置里
     * 留空 = 应用起不来。Optional 让"没配判官模型"回到文档承诺的"校验关闭"。
     */
    @ConfigProperty(name = "ai.guardrail.topic-verification.model")
    Optional<String> model;

    @ConfigProperty(name = "ai.guardrail.topic-verification.timeout", defaultValue = "PT12S")
    Duration timeout;

    private final Jsonb jsonb = JsonbBuilder.create();

    // Package-private so tests can install a fake judge without an Ollama endpoint.
    volatile ChatModel judge;

    @PostConstruct
    void logConfiguration() {
        if (enabled && judgeModel() == null) {
            LOG.warning("Topic verification stays off: configure ai.guardrail.topic-verification.model "
                    + "with a judge stronger than the chat model to enable it");
        }
    }

    public boolean isEnabled() {
        return enabled && judgeModel() != null;
    }

    /** 判官模型名；未配置或全是空白时返回 null，表示校验关闭。 */
    private String judgeModel() {
        if (model == null || model.isEmpty()) {
            return null;
        }
        String value = model.get();
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    public GroundingDecision verify(
            String question,
            String answer,
            List<RagQueryService.RetrievedChunk> sources
    ) {
        if (!shouldVerify(question, answer, sources)) {
            return GroundingDecision.allowed(answer);
        }
        String prompt = buildPrompt(question, answer, sources);
        try {
            ChatRequest request = ChatRequest.builder()
                    .messages(UserMessage.from(prompt))
                    .responseFormat(ResponseFormat.JSON)
                    .build();
            ChatResponse response = judge().chat(request);
            String raw = response == null || response.aiMessage() == null
                    ? null
                    : response.aiMessage().text();
            if (Boolean.FALSE.equals(parseVerdict(raw))) {
                LOG.info("Topic verification refused an answer: sources do not cover the asked subject");
                return GroundingDecision.refused(AnswerGroundingPolicy.NO_SOURCE_ANSWER, "topic_mismatch");
            }
        } catch (RuntimeException ex) {
            LOG.log(Level.FINE, "Topic verification skipped", ex);
        }
        return GroundingDecision.allowed(answer);
    }

    private boolean shouldVerify(
            String question,
            String answer,
            List<RagQueryService.RetrievedChunk> sources
    ) {
        if (!isEnabled() || question == null || question.isBlank() || answer == null || answer.isBlank()) {
            return false;
        }
        if (sources == null || sources.isEmpty()) {
            return false;
        }
        if (AnswerGroundingPolicy.NO_SOURCE_ANSWER.equals(answer)
                || AnswerGroundingPolicy.UNCITED_ANSWER.equals(answer)) {
            return false;
        }
        boolean hasUsableSource = false;
        for (RagQueryService.RetrievedChunk source : sources) {
            // Web snippets are live search results, not curated knowledge; the calibrated prompt
            // was built for knowledge-base passages and should not judge them.
            if ("WEB_SEARCH".equalsIgnoreCase(source.sourceType())) {
                return false;
            }
            hasUsableSource |= source.content() != null && !source.content().isBlank();
        }
        return hasUsableSource;
    }

    private ChatModel judge() {
        ChatModel current = judge;
        if (current != null) {
            return current;
        }
        if (judgeFactory == null) {
            throw new IllegalStateException("Judge model factory is not configured");
        }
        Duration effectiveTimeout = timeout == null ? Duration.ofSeconds(12) : timeout;
        String judgeModel = judgeModel();
        if (judgeModel == null) {
            throw new IllegalStateException("Topic verification judge model is not configured");
        }
        synchronized (this) {
            if (judge == null) {
                judge = judgeFactory.create(judgeModel, effectiveTimeout);
            }
            return judge;
        }
    }

    private static String buildPrompt(
            String question,
            String answer,
            List<RagQueryService.RetrievedChunk> sources
    ) {
        StringBuilder context = new StringBuilder();
        int index = 1;
        for (RagQueryService.RetrievedChunk source : sources) {
            String content = source.content() == null ? "" : source.content().strip();
            if (content.isEmpty()) {
                continue;
            }
            if (!context.isEmpty()) {
                context.append('\n');
            }
            context.append('[').append(index).append("] ").append(content);
            index++;
        }
        return PROMPT_TEMPLATE.formatted(context, question.strip(), answer.strip());
    }

    private Boolean parseVerdict(String rawResponse) {
        if (rawResponse == null || rawResponse.isBlank()) {
            return null;
        }
        Map<String, Object> node = readFirstObject(rawResponse);
        if (node == null) {
            return null;
        }
        Object verdict = node.get("topic_in_sources");
        if (verdict instanceof Boolean value) {
            return value;
        }
        if (verdict instanceof String text) {
            String trimmed = text.trim();
            if ("true".equalsIgnoreCase(trimmed)) {
                return Boolean.TRUE;
            }
            if ("false".equalsIgnoreCase(trimmed)) {
                return Boolean.FALSE;
            }
        }
        return null;
    }

    private Map<String, Object> readFirstObject(String rawResponse) {
        Map<String, Object> node = parseObject(rawResponse);
        if (node != null) {
            return node;
        }
        int start = rawResponse.indexOf('{');
        int end = rawResponse.lastIndexOf('}');
        if (start < 0 || end <= start) {
            return null;
        }
        return parseObject(rawResponse.substring(start, end + 1));
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> parseObject(String text) {
        try {
            Object parsed = jsonb.fromJson(text, Map.class);
            return parsed instanceof Map<?, ?> map ? (Map<String, Object>) map : null;
        } catch (RuntimeException ignored) {
            return null;
        }
    }
}
