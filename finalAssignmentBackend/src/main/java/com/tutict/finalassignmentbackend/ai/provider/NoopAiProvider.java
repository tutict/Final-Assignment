package com.tutict.finalassignmentbackend.ai.provider;

import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Map;

@Component
public class NoopAiProvider implements AiProvider {

    @Override
    public String providerName() {
        return "noop";
    }

    @Override
    public boolean supportsStreaming() {
        return true;
    }

    @Override
    public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
        return Flux.just(
                new AiToken("AI \u670d\u52a1\u6682\u65f6\u4e0d\u53ef\u7528\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5", false,
                        Map.of("fallback", true, "isFallback", true, "reason", "provider_unavailable")),
                new AiToken("", true,
                        Map.of("fallback", true, "isFallback", true, "reason", "provider_unavailable"))
        );
    }

    @Override
    public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
        return Mono.just(new AiMessage("AI provider unavailable.", Map.of("fallback", true)));
    }

    @Override
    public Mono<ProviderHealth> health() {
        return Mono.just(ProviderHealth.up("noop fallback ready"));
    }
}
