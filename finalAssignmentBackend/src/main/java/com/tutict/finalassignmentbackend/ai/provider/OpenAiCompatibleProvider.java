package com.tutict.finalassignmentbackend.ai.provider;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.chat.AiRateLimitException;
import com.tutict.finalassignmentbackend.ai.chat.ExternalApiSlotLimiter;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.ClientResponse;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;

import java.time.Duration;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

@Component
public class OpenAiCompatibleProvider implements AiProvider {

    private static final Duration MAX_RETRY_AFTER = Duration.ofSeconds(15);

    private final AiProviderProperties properties;
    private final WebClient.Builder webClientBuilder;
    private final ObjectMapper objectMapper;
    private final ExternalApiSlotLimiter slotLimiter;

    public OpenAiCompatibleProvider(
            AiProviderProperties properties,
            WebClient.Builder webClientBuilder,
            ObjectMapper objectMapper
    ) {
        this(properties, webClientBuilder, objectMapper, null);
    }

    @org.springframework.beans.factory.annotation.Autowired
    public OpenAiCompatibleProvider(
            AiProviderProperties properties,
            WebClient.Builder webClientBuilder,
            ObjectMapper objectMapper,
            ObjectProvider<ExternalApiSlotLimiter> slotLimiter
    ) {
        this.properties = properties;
        this.webClientBuilder = webClientBuilder;
        this.objectMapper = objectMapper;
        this.slotLimiter = slotLimiter == null ? null : slotLimiter.getIfAvailable();
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
        return protectAndRequeue(() -> rawStream(prompt, options));
    }

    @Override
    public Mono<AiMessage> complete(AiChatPrompt prompt, AiGenerationOptions options) {
        if (!enabled()) {
            return Mono.error(new IllegalStateException("OpenAI-compatible provider is disabled"));
        }
        Flux<AiToken> tokens = protectAndRequeue(() -> rawComplete(prompt, options)
                .map(message -> new AiToken(message.text(), true, sanitized(message.metadata())))
                .flux());
        return tokens.reduce(
                new StringBuilder(),
                (buffer, token) -> buffer.append(token.text() == null ? "" : token.text())
        ).map(buffer -> new AiMessage(buffer.toString(), Map.of("provider", providerName())));
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
                .onErrorResume(error -> Mono.just(ProviderHealth.down(sanitize(error.getMessage()))));
    }

    private Flux<AiToken> protectAndRequeue(Supplier<Flux<AiToken>> work) {
        Flux<AiToken> protectedWork = slotLimiter == null
                ? Flux.defer(work)
                : slotLimiter.protect(Flux.defer(work));
        int maxRetries = Math.max(0, properties.getOpenaiCompatible().getMaxRateLimitRetries());
        if (maxRetries == 0) {
            return protectedWork;
        }
        return protectedWork.retryWhen(Retry.from(companion -> companion.concatMap(signal -> {
            if (signal.failure() instanceof AiRateLimitException rateLimit
                    && signal.totalRetries() < maxRetries) {
                return Mono.delay(cappedRetryAfter(rateLimit.retryAfter()));
            }
            return Mono.error(signal.failure());
        })));
    }

    private Flux<AiToken> rawStream(AiChatPrompt prompt, AiGenerationOptions options) {
        return client()
                .post()
                .uri("/chat/completions")
                .headers(this::applyAuth)
                .bodyValue(requestBody(prompt, true))
                .retrieve()
                .onStatus(this::isTooManyRequests, this::rateLimited)
                .bodyToFlux(String.class)
                .flatMapIterable(this::parseStreamChunk)
                .timeout(options.streamingTimeout());
    }

    private Mono<AiMessage> rawComplete(AiChatPrompt prompt, AiGenerationOptions options) {
        return client()
                .post()
                .uri("/chat/completions")
                .headers(this::applyAuth)
                .bodyValue(requestBody(prompt, false))
                .retrieve()
                .onStatus(this::isTooManyRequests, this::rateLimited)
                .bodyToMono(String.class)
                .timeout(options.timeout())
                .map(this::readJson)
                .map(node -> new AiMessage(extractMessage(node), Map.of("provider", providerName())));
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

    private boolean isTooManyRequests(HttpStatusCode status) {
        return status.value() == 429;
    }

    private Mono<? extends Throwable> rateLimited(ClientResponse response) {
        Duration retryAfter = parseRetryAfter(response.headers().asHttpHeaders());
        return response.releaseBody().then(Mono.error(new AiRateLimitException(retryAfter)));
    }

    static Duration parseRetryAfter(HttpHeaders headers) {
        String raw = headers == null ? null : headers.getFirst(HttpHeaders.RETRY_AFTER);
        if (raw == null || raw.isBlank()) {
            return Duration.ofSeconds(1);
        }
        try {
            long seconds = Long.parseLong(raw.trim());
            if (seconds <= 0) {
                return Duration.ofMillis(200);
            }
            return Duration.ofSeconds(seconds);
        } catch (NumberFormatException ignored) {
            try {
                ZonedDateTime when = ZonedDateTime.parse(raw.trim(), DateTimeFormatter.RFC_1123_DATE_TIME);
                Duration delay = Duration.between(ZonedDateTime.now(when.getZone()), when);
                return delay.isNegative() || delay.isZero() ? Duration.ofSeconds(1) : delay;
            } catch (RuntimeException ignoredDate) {
                return Duration.ofSeconds(1);
            }
        }
    }

    private static Duration cappedRetryAfter(Duration retryAfter) {
        if (retryAfter == null || retryAfter.isNegative() || retryAfter.isZero()) {
            return Duration.ofSeconds(1);
        }
        return retryAfter.compareTo(MAX_RETRY_AFTER) > 0 ? MAX_RETRY_AFTER : retryAfter;
    }

    private Map<String, Object> requestBody(AiChatPrompt prompt, boolean stream) {
        java.util.LinkedHashMap<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("model", properties.getOpenaiCompatible().getChatModel());
        body.put("stream", stream);
        body.put("messages", AiProviderToolSupport.messagesFrom(prompt));
        java.util.List<java.util.Map<String, Object>> tools = AiProviderToolSupport.toolsFrom(prompt);
        if (!tools.isEmpty()) {
            body.put("tools", tools);
        }
        return body;
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
                java.util.List<java.util.Map<String, Object>> toolCalls = AiProviderToolSupport.parseToolCalls(node);
                java.util.Map<String, Object> metadata = toolCalls.isEmpty()
                        ? Map.of()
                        : Map.of("toolCalls", toolCalls);
                if (!text.isEmpty() || finished || !toolCalls.isEmpty()) {
                    tokens.add(new AiToken(text, finished, sanitized(metadata)));
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

    private static Map<String, Object> sanitized(Map<String, Object> metadata) {
        if (metadata == null || metadata.isEmpty()) {
            return Map.of();
        }
        java.util.LinkedHashMap<String, Object> copy = new java.util.LinkedHashMap<>();
        metadata.forEach((key, value) -> {
            if (key == null) {
                return;
            }
            String lower = key.toLowerCase();
            if (lower.contains("api") && lower.contains("key")
                    || lower.contains("authorization")
                    || lower.contains("secret")) {
                return;
            }
            copy.put(key, value);
        });
        return copy;
    }

    private static String sanitize(String message) {
        if (message == null) {
            return "OpenAI-compatible endpoint unreachable";
        }
        return message.replaceAll("(?i)(api[_-]?key|authorization|bearer)\\s*[=:]\\s*\\S+", "$1=***");
    }
}
