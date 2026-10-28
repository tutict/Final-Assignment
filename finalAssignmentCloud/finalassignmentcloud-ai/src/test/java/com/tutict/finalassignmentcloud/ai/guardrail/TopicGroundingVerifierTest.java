package com.tutict.finalassignmentcloud.ai.guardrail;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import com.tutict.finalassignmentcloud.ai.provider.AiChatPrompt;
import com.tutict.finalassignmentcloud.ai.provider.AiGenerationOptions;
import com.tutict.finalassignmentcloud.ai.provider.AiMessage;
import com.tutict.finalassignmentcloud.ai.provider.AiProvider;
import com.tutict.finalassignmentcloud.ai.provider.AiProviderProperties;
import com.tutict.finalassignmentcloud.ai.provider.AiProviderRegistry;
import com.tutict.finalassignmentcloud.ai.provider.AiToken;
import com.tutict.finalassignmentcloud.ai.provider.NoopAiProvider;
import com.tutict.finalassignmentcloud.ai.provider.ProviderHealth;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

class TopicGroundingVerifierTest {

    private final AtomicReference<AiChatPrompt> prompt = new AtomicReference<>();
    private final AtomicReference<AiGenerationOptions> options = new AtomicReference<>();

    @Test
    void refusesWhenSourcesDoNotCoverTheAskedSubject() {
        TopicGroundingVerifier verifier = verifier("{\"topic_in_sources\":false,\"reason\":\"资料讲的是过户\"}");

        GroundingDecision decision = verifier.verify(
                        "车辆报废流程是什么？",
                        "车辆过户需买卖双方携带身份证办理 [1]。",
                        List.of(source("车辆过户办理：车辆过户需买卖双方携带身份证、行驶证到车管所办理。", "BUSINESS"))
                )
                .block(Duration.ofSeconds(2));

        assertThat(decision).isNotNull();
        assertThat(decision.grounded()).isFalse();
        assertThat(decision.reason()).isEqualTo("topic_mismatch");
        assertThat(decision.answer()).isEqualTo(AnswerGroundingPolicy.NO_SOURCE_ANSWER);
        assertThat(prompt.get().message())
                .contains("车辆报废流程是什么？")
                .contains("车辆过户需买卖双方携带身份证办理")
                .contains("[1] 车辆过户办理");
    }

    @Test
    void allowsWhenSourcesCoverTheAskedSubject() {
        TopicGroundingVerifier verifier = verifier("{\"topic_in_sources\":true,\"reason\":\"主题一致\"}");

        GroundingDecision decision = verifier.verify(
                        "罚款怎么缴纳？",
                        "罚款可通过微信、支付宝缴纳 [1]。",
                        List.of(source("罚款支持微信支付、支付宝、银行卡转账和现金四种缴纳渠道。", "BUSINESS"))
                )
                .block(Duration.ofSeconds(2));

        assertThat(decision).isNotNull();
        assertThat(decision.grounded()).isTrue();
        assertThat(decision.answer()).isEqualTo("罚款可通过微信、支付宝缴纳 [1]。");
    }

    @Test
    void verificationUsesDedicatedModelAndJsonOutput() {
        TopicGroundingVerifier verifier = verifier("{\"topic_in_sources\":true,\"reason\":\"ok\"}");

        verifier.verify("问题", "回答 [1]", List.of(source("资料", "BUSINESS")))
                .block(Duration.ofSeconds(2));

        assertThat(options.get()).isNotNull();
        assertThat(options.get().model()).isEqualTo("qwen2.5:7b");
        assertThat(options.get().responseFormat())
                .containsEntry("type", "object")
                .containsKey("properties");
        assertThat(options.get().temperature()).isEqualTo(0.0);
        assertThat(options.get().retryAttempts()).isZero();
    }

    @Test
    void failsOpenWhenJudgeOutputIsNotParseable() {
        TopicGroundingVerifier verifier = verifier("我觉得主题是一致的");

        GroundingDecision decision = verifier.verify("问题", "回答 [1]", List.of(source("资料", "BUSINESS")))
                .block(Duration.ofSeconds(2));

        assertThat(decision).isNotNull();
        assertThat(decision.grounded()).isTrue();
    }

    @Test
    void failsOpenWhenProviderFails() {
        TopicGroundingVerifier verifier = verifier(Mono.error(new IllegalStateException("judge down")));

        GroundingDecision decision = verifier.verify("问题", "回答 [1]", List.of(source("资料", "BUSINESS")))
                .block(Duration.ofSeconds(2));

        assertThat(decision).isNotNull();
        assertThat(decision.grounded()).isTrue();
    }

    @Test
    void skipsWhenDisabledOrNotApplicable() {
        TopicGroundingVerifier disabled = new TopicGroundingVerifier(
                registry(Mono.just(new AiMessage("{\"topic_in_sources\":false}", Map.of()))),
                new ObjectMapper(), false, "qwen2.5:7b", Duration.ofSeconds(2));
        TopicGroundingVerifier enabled = verifier("{\"topic_in_sources\":false}");

        assertThat(disabled.verify("问题", "回答 [1]", List.of(source("资料", "BUSINESS")))
                .block(Duration.ofSeconds(2)).grounded()).isTrue();
        assertThat(enabled.verify("问题", "回答 [1]", List.of()).block(Duration.ofSeconds(2)).grounded()).isTrue();
        assertThat(enabled.verify("问题", AnswerGroundingPolicy.NO_SOURCE_ANSWER,
                List.of(source("资料", "BUSINESS"))).block(Duration.ofSeconds(2)).grounded()).isTrue();
        assertThat(enabled.verify("问题", "回答 [1]", List.of(source("网页摘要", "WEB_SEARCH")))
                .block(Duration.ofSeconds(2)).grounded()).isTrue();
        assertThat(prompt.get()).isNull();
    }

    @Test
    void staysOffWhenNoJudgeModelIsConfigured() {
        TopicGroundingVerifier verifier = new TopicGroundingVerifier(
                registry(Mono.just(new AiMessage("{\"topic_in_sources\":false}", Map.of()))),
                new ObjectMapper(), true, "", Duration.ofSeconds(2));

        assertThat(verifier.isEnabled()).isFalse();
        assertThat(verifier.verify("问题", "回答 [1]", List.of(source("资料", "BUSINESS")))
                .block(Duration.ofSeconds(2)).grounded()).isTrue();
        assertThat(prompt.get()).isNull();
    }

    private TopicGroundingVerifier verifier(String completion) {
        return verifier(Mono.just(new AiMessage(completion, Map.of())));
    }

    private TopicGroundingVerifier verifier(Mono<AiMessage> completion) {
        return new TopicGroundingVerifier(
                registry(completion),
                new ObjectMapper(),
                true,
                "qwen2.5:7b",
                Duration.ofSeconds(2)
        );
    }

    private AiProviderRegistry registry(Mono<AiMessage> completion) {
        AiProvider provider = new AiProvider() {
            @Override
            public String providerName() {
                return "judge";
            }

            @Override
            public boolean supportsStreaming() {
                return false;
            }

            @Override
            public Flux<AiToken> stream(AiChatPrompt request, AiGenerationOptions generationOptions) {
                return Flux.empty();
            }

            @Override
            public Mono<AiMessage> complete(AiChatPrompt request, AiGenerationOptions generationOptions) {
                prompt.set(request);
                options.set(generationOptions);
                return completion;
            }

            @Override
            public Mono<ProviderHealth> health() {
                return Mono.just(ProviderHealth.up("ok"));
            }
        };
        AiProviderProperties properties = new AiProviderProperties();
        properties.getProvider().setPrimary("judge");
        properties.getProvider().setFallback("noop");
        properties.getProvider().setTimeout(Duration.ofSeconds(2));
        properties.getProvider().setRetryAttempts(0);
        return new AiProviderRegistry(List.of(provider, new NoopAiProvider()), properties);
    }

    private static RagRetrievalResult source(String content, String sourceType) {
        return new RagRetrievalResult(
                "chunk-1", "doc-1", content, "资料标题", sourceType, "docs", "1", "body", "/route",
                0.5, 0.6, 0.8, Map.of());
    }
}
