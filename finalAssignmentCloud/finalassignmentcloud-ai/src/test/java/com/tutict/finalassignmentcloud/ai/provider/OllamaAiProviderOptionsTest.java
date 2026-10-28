package com.tutict.finalassignmentcloud.ai.provider;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class OllamaAiProviderOptionsTest {

    private final AiProviderProperties properties = new AiProviderProperties();
    private final OllamaAiProvider provider = new OllamaAiProvider(
            properties,
            WebClient.builder(),
            new ObjectMapper()
    );

    @Test
    void sendsConfiguredTemperatureByDefault() {
        Map<String, Object> body = provider.requestBody(
                new AiChatPrompt("hello", Map.of()),
                true,
                AiGenerationOptions.from(properties, Map.of())
        );

        assertThat(options(body)).containsEntry("temperature", 0.2);
        assertThat(options(body)).doesNotContainKey("num_predict");
    }

    @Test
    void explicitGenerationOptionsOverrideTemperatureAndSetMaxTokens() {
        Map<String, Object> body = provider.requestBody(
                new AiChatPrompt("hello", Map.of()),
                false,
                new AiGenerationOptions(
                        Duration.ofSeconds(5),
                        Duration.ofSeconds(5),
                        0,
                        0.7,
                        256,
                        Map.of()
                )
        );

        assertThat(options(body))
                .containsEntry("temperature", 0.7)
                .containsEntry("num_predict", 256);
    }

    @Test
    void honorsPropertyOverrideForTemperature() {
        properties.getOllama().setTemperature(0.35);

        Map<String, Object> body = provider.requestBody(
                new AiChatPrompt("hello", Map.of()),
                true,
                AiGenerationOptions.from(properties, Map.of())
        );

        assertThat(options(body)).containsEntry("temperature", 0.35);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> options(Map<String, Object> body) {
        return (Map<String, Object>) body.get("options");
    }
}
