package finalassignmentbackend.ai.guardrail;

import finalassignmentbackend.ai.chat.ChatStreamEvent;
import finalassignmentbackend.rag.service.RagQueryService;
import io.smallrye.mutiny.Multi;
import io.smallrye.mutiny.infrastructure.Infrastructure;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Supplier;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 答案层护栏：缓冲一次纯文本回答，按 Spring 参考顺序执行
 * 清洗 → 引用强制（一次引用修复）→ 主题校验，然后回放事件。
 *
 * <p>只有 TOKEN 事件受判定约束；任何控制事件或基础设施错误都原样透传，否则一次拒答会
 * 吞掉错误帧，或把"模型繁忙"改写成引用拒答。DONE 由上层流水线统一追加，这里不重复生成。
 *
 * <p>判定与修复都在 worker 线程执行（{@code runSubscriptionOn}），避免阻塞 Vert.x 事件循环。
 */
@ApplicationScoped
public class GuardrailStage {

    private static final Logger LOG = Logger.getLogger(GuardrailStage.class.getName());

    private static final Duration REPAIR_TIMEOUT = Duration.ofSeconds(180);

    @Inject AnswerGroundingPolicy policy;

    /**
     * @param events  模型 token 事件流
     * @param question 已经过提示注入清洗的用户问题
     * @param sources 实际放入提示词的来源
     * @param repair  一次引用修复回调；无来源时为 {@code null}
     */
    public Multi<ChatStreamEvent> apply(
            Multi<ChatStreamEvent> events,
            String question,
            List<RagQueryService.RetrievedChunk> sources,
            Supplier<Multi<ChatStreamEvent>> repair
    ) {
        List<RagQueryService.RetrievedChunk> judgedSources =
                sources == null ? List.of() : List.copyOf(sources);
        return Multi.createFrom().deferred(() -> events
                .collect().asList()
                .onItem().transformToMulti(buffered ->
                        resolveAsync(buffered, question, judgedSources, repair)));
    }

    private Multi<ChatStreamEvent> resolveAsync(
            List<ChatStreamEvent> buffered,
            String question,
            List<RagQueryService.RetrievedChunk> sources,
            Supplier<Multi<ChatStreamEvent>> repair
    ) {
        return Multi.createFrom().deferred(() ->
                        Multi.createFrom().iterable(resolve(buffered, question, sources, repair)))
                .runSubscriptionOn(Infrastructure.getDefaultWorkerPool());
    }

    private List<ChatStreamEvent> resolve(
            List<ChatStreamEvent> buffered,
            String question,
            List<RagQueryService.RetrievedChunk> sources,
            Supplier<Multi<ChatStreamEvent>> repair
    ) {
        if (buffered.isEmpty()) {
            return List.of();
        }
        if (buffered.stream().anyMatch(GuardrailStage::isNonTextEvent)) {
            return buffered;
        }
        String answer = joinTokens(buffered);
        String sanitized = AnswerTextSanitizer.sanitize(answer);

        // Do not let an answer made only of internal labels become a successful empty answer.
        if (!answer.isBlank() && (sanitized == null || sanitized.isBlank())) {
            return repair == null
                    ? List.of(singleAnswerToken(buffered, AnswerGroundingPolicy.UNCITED_ANSWER))
                    : retryWithCitations(buffered, question, sources, repair);
        }

        // Judge the user-visible text so stripped labels cannot satisfy grounding on their own.
        GroundingDecision decision = policy == null
                ? GroundingDecision.allowed(sanitized)
                : policy.evaluate(sanitized, sources);
        if (!decision.grounded()) {
            return repair == null
                    ? List.of(singleAnswerToken(buffered, decision.answer()))
                    : retryWithCitations(buffered, question, sources, repair);
        }

        List<ChatStreamEvent> replay = Objects.equals(sanitized, answer)
                ? buffered
                : List.of(singleAnswerToken(buffered, sanitized));
        return replay;
    }

    private List<ChatStreamEvent> retryWithCitations(
            List<ChatStreamEvent> buffered,
            String question,
            List<RagQueryService.RetrievedChunk> sources,
            Supplier<Multi<ChatStreamEvent>> repair
    ) {
        ChatStreamEvent first = buffered.getFirst();
        LOG.info(() -> "Retrying uncited answer with citation repair. messageId=" + first.messageId());
        List<ChatStreamEvent> retryEvents;
        try {
            // Keep the first attempt's identity so one stream never mixes message ids.
            retryEvents = repair.get()
                    .map(event -> rebind(event, first.sessionKey(), first.messageId()))
                    .collect().asList()
                    .await().atMost(REPAIR_TIMEOUT);
        } catch (RuntimeException ex) {
            LOG.log(Level.WARNING, "Citation repair failed; refusing the original answer", ex);
            return List.of(singleAnswerToken(buffered, AnswerGroundingPolicy.UNCITED_ANSWER));
        }
        // A failed repair gets no second attempt; its own error/control frames pass through.
        return resolve(retryEvents, question, sources, null);
    }

    private static String joinTokens(List<ChatStreamEvent> events) {
        StringBuilder answer = new StringBuilder();
        for (ChatStreamEvent event : events) {
            if (event.token() != null) {
                answer.append(event.token());
            }
        }
        return answer.toString();
    }

    private static ChatStreamEvent singleAnswerToken(List<ChatStreamEvent> buffered, String answer) {
        ChatStreamEvent first = buffered.getFirst();
        return ChatStreamEvent.token(first.sessionKey(), first.messageId(), answer);
    }

    private static ChatStreamEvent rebind(ChatStreamEvent event, String sessionKey, String messageId) {
        if (Objects.equals(event.sessionKey(), sessionKey) && Objects.equals(event.messageId(), messageId)) {
            return event;
        }
        return new ChatStreamEvent(
                event.type(),
                sessionKey,
                messageId,
                event.token(),
                event.payload(),
                event.timestamp()
        );
    }

    /**
     * 真正受引用强制约束的只有 TOKEN；其他类型以及任何带 {@code isFallback} 载荷的事件
     * 都视为非文本事件。
     */
    private static boolean isNonTextEvent(ChatStreamEvent event) {
        if (!"token".equals(event.type())) {
            return true;
        }
        return event.payload() instanceof Map<?, ?> payload
                && Boolean.TRUE.equals(payload.get("isFallback"));
    }
}
