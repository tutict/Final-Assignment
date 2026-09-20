package com.tutict.finalassignmentbackend.ai.provider;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@Component
public class MockAiProvider implements AiProvider {

    private static final Logger logger = LoggerFactory.getLogger(MockAiProvider.class);

    private final List<String> tokens;
    private final Duration minDelay;
    private final Duration maxDelay;

    public MockAiProvider() {
        this(
                List.of("你好", "，我", "是", "Mock", "AI"),
                Duration.ofMillis(50),
                Duration.ofMillis(150)
        );
    }

    public MockAiProvider(List<String> tokens, Duration minDelay, Duration maxDelay) {
        this.tokens = List.copyOf(tokens);
        this.minDelay = minDelay;
        this.maxDelay = maxDelay;
    }

    @Override
    public String providerName() {
        return "mock";
    }

    @Override
    public boolean supportsStreaming() {
        return true;
    }

    @Override
    public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
        List<Map<String, Object>> tools = AiProviderToolSupport.toolsFrom(prompt);
        if (!tools.isEmpty()) {
            if (AiProviderToolSupport.hasToolMessages(prompt)) {
                return delayedTokens(List.of("已根据办理结果整理如下。"));
            }
            String toolName = selectTool(prompt, tools);
            if (toolName != null) {
                Map<String, Object> call = new LinkedHashMap<>();
                call.put("id", "mock-tool-1");
                call.put("name", toolName);
                call.put("arguments", Map.of());
                return Flux.just(new AiToken("", true, Map.of("toolCalls", List.of(call))));
            }
        }
        return delayedTokens(tokens)
                .doOnCancel(() -> logger.info("Mock AI provider stream canceled."));
    }

    @Override
    public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
        return stream(prompt, options)
                .filter(token -> token.text() != null && !token.text().isBlank())
                .map(AiToken::text)
                .collectList()
                .map(parts -> new AiMessage(String.join("", parts), Map.of()));
    }

    @Override
    public Mono<ProviderHealth> health() {
        return Mono.just(ProviderHealth.up("mock provider ready"));
    }

    private Flux<AiToken> delayedTokens(List<String> values) {
        Flux<AiToken> tokenEvents = Flux.fromIterable(values)
                .concatMap(token -> Mono.delay(randomDelay())
                        .thenReturn(new AiToken(token, false, Map.of())));
        return tokenEvents.concatWithValues(new AiToken("", true, Map.of()));
    }

    private static String selectTool(AiChatPrompt prompt, List<Map<String, Object>> tools) {
        List<String> names = new ArrayList<>();
        for (Map<String, Object> tool : tools) {
            Object function = tool.get("function");
            if (function instanceof Map<?, ?> map) {
                Object name = map.get("name");
                if (name != null && !name.toString().isBlank()) {
                    names.add(name.toString());
                }
            }
        }
        String user = AiProviderToolSupport.lastUserContent(prompt).toLowerCase(Locale.ROOT);
        for (String name : names) {
            if ("confirm_draft".equals(name) && (user.contains("确认") || user.contains("confirm"))) {
                return name;
            }
        }
        if (user.contains("违法") && names.contains("query_my_offenses")) {
            return "query_my_offenses";
        }
        if (user.contains("违法") && names.contains("query_offenses")) {
            return "query_offenses";
        }
        if ((user.contains("罚款") || user.contains("缴")) && names.contains("query_my_fines")) {
            return "query_my_fines";
        }
        for (String name : names) {
            if (!"confirm_draft".equals(name) && name.startsWith("query_")) {
                return name;
            }
        }
        return names.isEmpty() ? null : names.getFirst();
    }

    private Duration randomDelay() {
        long minMillis = Math.max(1, minDelay.toMillis());
        long maxMillis = Math.max(minMillis, maxDelay.toMillis());
        return Duration.ofMillis(ThreadLocalRandom.current().nextLong(minMillis, maxMillis + 1));
    }
}
