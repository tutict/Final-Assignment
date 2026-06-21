package com.tutict.finalassignmentcloud.ai.provider;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Component
public class OpenAiCompatibleProvider implements AiProvider {

    private final AiProviderProperties properties;
    private final WebClient.Builder webClientBuilder;
    private final ObjectMapper objectMapper;

    public OpenAiCompatibleProvider(
            AiProviderProperties properties,
            WebClient.Builder webClientBuilder,
            ObjectMapper objectMapper
    ) {
        this.properties = properties;
        this.webClientBuilder = webClientBuilder;
        this.objectMapper = objectMapper;
    }

    @Override
    public String providerName() {
        return "openai-compatible";
    }

    @Override
    public boolean supportsStreaming() {
        return true;
    }

    @Override
    public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
        if (!enabled()) {
            return Flux.error(new IllegalStateException("OpenAI-compatible provider is disabled"));
        }
        return client()
                .post()
                .uri("/chat/completions")
                .headers(this::applyAuth)
                .bodyValue(requestBody(prompt, true))
                .retrieve()
                .bodyToFlux(String.class)
                .flatMapIterable(this::parseStreamChunk)
                .timeout(options.streamingTimeout());
    }

    @Override
    public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
        if (!enabled()) {
            return Mono.error(new IllegalStateException("OpenAI-compatible provider is disabled"));
        }
        return client()
                .post()
                .uri("/chat/completions")
                .headers(this::applyAuth)
                .bodyValue(requestBody(prompt, false))
                .retrieve()
                .bodyToMono(String.class)
                .timeout(options.timeout())
                .map(this::readJson)
                .map(node -> new AiMessage(extractMessage(node), Map.of("provider", providerName())));
    }

    @Override
    public Mono<ProviderHealth> health() {
        if (!enabled()) {
            return Mono.just(ProviderHealth.down("OpenAI-compatible provider disabled"));
        }
        return client()
                .get()
                .uri("/models")
                .headers(this::applyAuth)
                .retrieve()
                .toBodilessEntity()
                .timeout(properties.getProvider().getTimeout())
                .map(response -> ProviderHealth.up("OpenAI-compatible endpoint reachable"))
                .onErrorResume(error -> Mono.just(ProviderHealth.down(error.getMessage())));
    }

    private boolean enabled() {
        return properties.getOpenaiCompatible().isEnabled()
                && properties.getOpenaiCompatible().getBaseUrl() != null
                && !properties.getOpenaiCompatible().getBaseUrl().isBlank()
                && properties.getOpenaiCompatible().getChatModel() != null
                && !properties.getOpenaiCompatible().getChatModel().isBlank();
    }

    private WebClient client() {
        return webClientBuilder.baseUrl(properties.getOpenaiCompatible().getBaseUrl()).build();
    }

    private void applyAuth(HttpHeaders headers) {
        String apiKey = properties.getOpenaiCompatible().getApiKey();
        if (apiKey != null && !apiKey.isBlank()) {
            headers.setBearerAuth(apiKey);
        }
    }

    private Map<String, Object> requestBody(AiChatPrompt prompt, boolean stream) {
        return Map.of(
                "model", properties.getOpenaiCompatible().getChatModel(),
                "stream", stream,
                "messages", List.of(Map.of("role", "user", "content", prompt.message()))
        );
    }

    private List<AiToken> parseStreamChunk(String chunk) {
        List<AiToken> tokens = new ArrayList<>();
        for (String rawLine : chunk.split("\\R")) {
            String line = rawLine.trim();
            if (line.isBlank()) {
                continue;
            }
            if (line.startsWith("data:")) {
                line = line.substring(5).trim();
            }
            if ("[DONE]".equals(line)) {
                tokens.add(new AiToken("", true, Map.of()));
                continue;
            }
            try {
                JsonNode node = objectMapper.readTree(line);
                String text = node.path("choices").path(0).path("delta").path("content").asText("");
                boolean finished = !node.path("choices").path(0).path("finish_reason").isMissingNode()
                        && !node.path("choices").path(0).path("finish_reason").isNull();
                if (!text.isEmpty() || finished) {
                    tokens.add(new AiToken(text, finished, Map.of()));
                }
            } catch (Exception ignored) {
                tokens.add(new AiToken("", false, Map.of("parse_error", true)));
            }
        }
        return tokens;
    }

    private String extractMessage(JsonNode node) {
        return node.path("choices")
                .path(0)
                .path("message")
                .path("content")
                .asText("");
    }

    private JsonNode readJson(String json) {
        try {
            return objectMapper.readTree(json);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to parse OpenAI-compatible response", ex);
        }
    }
}
