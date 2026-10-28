package com.tutict.finalassignmentcloud.ai.guardrail;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import com.tutict.finalassignmentcloud.ai.provider.AiGenerationOptions;
import com.tutict.finalassignmentcloud.ai.provider.AiProviderRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * 生成后主题校验：判断回答是否仍在回答用户所问的那个业务。
 *
 * <p>引用护栏只能证明“回答里的编号确实指向某段资料”，无法发现模型把问题换成了资料中
 * 另一类业务（例如问报废流程，回答却讲车辆过户）。这里让独立的校验模型同时看问题、
 * 检索资料和草稿回答，只有资料确实覆盖问题主题、且回答围绕该主题时才放行。
 *
 * <p>校验是<b>失败放行</b>的：超时、模型不可用、输出无法解析都不会拦截回答，避免把一次
 * 基础设施故障变成对所有用户的拒答。校验模型必须通过
 * {@code ai.guardrail.topic-verification.model} 显式指定；未配置时校验保持关闭，
 * 因为不应让生成答案的聊天模型审查自己的输出。
 */
@Component
public class TopicGroundingVerifier {

    private static final Logger logger = LoggerFactory.getLogger(TopicGroundingVerifier.class);

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

    private static final Map<String, Object> VERDICT_SCHEMA = Map.of(
            "type", "object",
            "properties", Map.of(
                    "topic_in_sources", Map.of("type", "boolean"),
                    "reason", Map.of("type", "string")),
            "required", List.of("topic_in_sources", "reason"));

    private final AiProviderRegistry providerRegistry;
    private final ObjectMapper objectMapper;
    private final boolean enabled;
    private final String model;
    private final Duration timeout;

    public TopicGroundingVerifier(
            AiProviderRegistry providerRegistry,
            ObjectMapper objectMapper,
            @Value("${ai.guardrail.topic-verification.enabled:true}") boolean enabled,
            @Value("${ai.guardrail.topic-verification.model:}") String model,
            @Value("${ai.guardrail.topic-verification.timeout:PT12S}") Duration timeout
    ) {
        this.providerRegistry = providerRegistry;
        this.objectMapper = objectMapper;
        this.model = model == null ? "" : model.trim();
        // The chat model must not audit its own answer, so a missing judge model means "off"
        // rather than silently reusing the chat provider and risking false refusals.
        this.enabled = enabled && !this.model.isBlank();
        this.timeout = timeout == null ? Duration.ofSeconds(12) : timeout;
        if (enabled && this.model.isBlank()) {
            logger.warn("Topic verification stays off: configure ai.guardrail.topic-verification.model "
                    + "with a judge stronger than the chat model to enable it");
        }
    }

    public boolean isEnabled() {
        return enabled;
    }

    public Mono<GroundingDecision> verify(String question, String answer, List<RagRetrievalResult> sources) {
        if (!shouldVerify(question, answer, sources)) {
            return Mono.just(GroundingDecision.allowed(answer));
        }
        String prompt = buildPrompt(question, answer, sources);
        return providerRegistry
                .completeIsolated(prompt, AiGenerationOptions.forVerification(timeout, model, VERDICT_SCHEMA))
                .timeout(timeout)
                .map(message -> decide(answer, message.text()))
                .onErrorResume(error -> {
                    logger.debug("Topic verification skipped: {}", error.toString());
                    return Mono.just(GroundingDecision.allowed(answer));
                });
    }

    private boolean shouldVerify(String question, String answer, List<RagRetrievalResult> sources) {
        if (!enabled || question == null || question.isBlank() || answer == null || answer.isBlank()) {
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
        for (RagRetrievalResult source : sources) {
            // Web snippets are live search results, not curated knowledge; the calibrated prompt
            // was built for knowledge-base passages and should not judge them.
            if ("WEB_SEARCH".equalsIgnoreCase(source.sourceType())) {
                return false;
            }
            hasUsableSource |= source.content() != null && !source.content().isBlank();
        }
        return hasUsableSource;
    }

    private static String buildPrompt(String question, String answer, List<RagRetrievalResult> sources) {
        StringBuilder context = new StringBuilder();
        int index = 1;
        for (RagRetrievalResult source : sources) {
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

    private GroundingDecision decide(String answer, String rawResponse) {
        Boolean verdict = parseVerdict(rawResponse);
        if (Boolean.FALSE.equals(verdict)) {
            logger.info("Topic verification refused an answer: sources do not cover the asked subject");
            return GroundingDecision.refused(AnswerGroundingPolicy.NO_SOURCE_ANSWER, "topic_mismatch");
        }
        return GroundingDecision.allowed(answer);
    }

    private Boolean parseVerdict(String rawResponse) {
        if (rawResponse == null || rawResponse.isBlank()) {
            return null;
        }
        JsonNode node = readFirstObject(rawResponse);
        if (node == null) {
            return null;
        }
        JsonNode verdict = node.path("topic_in_sources");
        if (verdict.isBoolean()) {
            return verdict.booleanValue();
        }
        if (verdict.isTextual()) {
            String text = verdict.asText("").trim();
            if ("true".equalsIgnoreCase(text)) {
                return Boolean.TRUE;
            }
            if ("false".equalsIgnoreCase(text)) {
                return Boolean.FALSE;
            }
        }
        return null;
    }

    private JsonNode readFirstObject(String rawResponse) {
        try {
            JsonNode node = objectMapper.readTree(rawResponse);
            if (node != null && node.isObject()) {
                return node;
            }
        } catch (Exception ignored) {
            // Fall through to the lenient slice below.
        }
        int start = rawResponse.indexOf('{');
        int end = rawResponse.lastIndexOf('}');
        if (start < 0 || end <= start) {
            return null;
        }
        try {
            JsonNode node = objectMapper.readTree(rawResponse.substring(start, end + 1));
            return node != null && node.isObject() ? node : null;
        } catch (Exception ignored) {
            return null;
        }
    }
}
