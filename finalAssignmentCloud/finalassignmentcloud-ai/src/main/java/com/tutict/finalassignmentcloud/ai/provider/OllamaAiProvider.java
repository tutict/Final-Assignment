package com.tutict.finalassignmentcloud.ai.provider;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Component
public class OllamaAiProvider implements AiProvider {

    private final AiProviderProperties properties;
    private final WebClient.Builder webClientBuilder;
    private final ObjectMapper objectMapper;

    public OllamaAiProvider(
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
        return "ollama";
    }

    @Override
    public boolean supportsStreaming() {
        return true;
    }

    @Override
    public Flux<AiToken> stream(AiChatPrompt prompt, AiGenerationOptions options) {
        if (!properties.getOllama().isEnabled()) {
            return Flux.error(new IllegalStateException("Ollama provider is disabled"));
        }
        return client()
                .post()
                .uri("/api/chat")
                .bodyValue(requestBody(prompt, true, options))
                .retrieve()
                .bodyToFlux(String.class)
                .flatMapIterable(this::parseStreamChunk)
                .timeout(options.streamingTimeout())
                .doOnCancel(() -> {
                });
    }

    @Override
    public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
        if (!properties.getOllama().isEnabled()) {
            return Mono.error(new IllegalStateException("Ollama provider is disabled"));
        }
        return client()
                .post()
                .uri("/api/chat")
                .bodyValue(requestBody(prompt, false, options))
                .retrieve()
                .bodyToMono(String.class)
                .timeout(options.timeout())
                .map(this::readJson)
                .map(node -> new AiMessage(extractText(node), Map.of("provider", providerName())));
    }

    @Override
    public Mono<ProviderHealth> health() {
        if (!properties.getOllama().isEnabled()) {
            return Mono.just(ProviderHealth.down("ollama provider disabled"));
        }
        return client()
                .get()
                .uri("/api/tags")
                .retrieve()
                .toBodilessEntity()
                .timeout(properties.getProvider().getTimeout())
                .map(response -> ProviderHealth.up("ollama reachable"))
                .onErrorResume(error -> Mono.just(ProviderHealth.down(error.getMessage())));
    }

    private WebClient client() {
        reactor.netty.http.client.HttpClient httpClient = reactor.netty.http.client.HttpClient.create()
                .option(io.netty.channel.ChannelOption.CONNECT_TIMEOUT_MILLIS, 1000);
        return webClientBuilder.clone()
                .baseUrl(properties.getOllama().getBaseUrl())
                .clientConnector(new org.springframework.http.client.reactive.ReactorClientHttpConnector(httpClient))
                .build();
    }

    Map<String, Object> requestBody(AiChatPrompt prompt, boolean stream, AiGenerationOptions options) {
        java.util.LinkedHashMap<String, Object> body = new java.util.LinkedHashMap<>();
        String model = options.model() == null || options.model().isBlank()
                ? properties.getOllama().getChatModel()
                : options.model().trim();
        body.put("model", model);
        body.put("stream", stream);
        if (options.responseFormat() != null && !options.responseFormat().isEmpty()) {
            body.put("format", options.responseFormat());
        }
        body.put("messages", List.of(Map.of("role", "user", "content", prompt.message())));
        java.util.LinkedHashMap<String, Object> ollamaOptions = new java.util.LinkedHashMap<>();
        Double temperature = options.temperature() == null
                ? properties.getOllama().getTemperature()
                : options.temperature();
        if (temperature != null) {
            ollamaOptions.put("temperature", temperature);
        }
        if (options.maxTokens() != null) {
            ollamaOptions.put("num_predict", options.maxTokens());
        }
        if (!ollamaOptions.isEmpty()) {
            body.put("options", ollamaOptions);
        }
        return body;
    }

    private List<AiToken> parseStreamChunk(String chunk) {
        List<AiToken> tokens = new ArrayList<>();
        for (String line : chunk.split("\\R")) {
            if (line.isBlank()) {
                continue;
            }
            JsonNode node = readJson(line);
            boolean finished = node.path("done").asBoolean(false);
            tokens.add(new AiToken(extractText(node), finished, Map.of()));
        }
        return tokens;
    }

    private JsonNode readJson(String json) {
        try {
            return objectMapper.readTree(json);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to parse Ollama response", ex);
        }
    }

    private String extractText(JsonNode node) {
        JsonNode message = node.path("message");
        if (message.hasNonNull("content")) {
            return message.path("content").asText("");
        }
        return node.path("response").asText("");
    }
}
