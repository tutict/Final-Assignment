package com.tutict.finalassignmentbackend.ai.chat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.http.codec.ServerSentEvent;

import static org.assertj.core.api.Assertions.assertThat;

class SseEventSerializationTest {

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();
    private final StreamEventWriter writer = new StreamEventWriter(objectMapper);

    @Test
    void serializesTokenAsTypedSseEvent() throws Exception {
        ChatStreamEvent event = ChatStreamEvent.token("session-1", "message-1", "你好");

        ServerSentEvent<String> sse = writer.toServerSentEvent(event);
        JsonNode data = objectMapper.readTree(sse.data());

        assertThat(sse.event()).isEqualTo("token");
        assertThat(data.get("type").asText()).isEqualTo("token");
        assertThat(data.get("sessionKey").asText()).isEqualTo("session-1");
        assertThat(data.get("messageId").asText()).isEqualTo("message-1");
        assertThat(data.get("token").asText()).isEqualTo("你好");
        assertThat(data.hasNonNull("timestamp")).isTrue();
    }

    @Test
    void serializesErrorWithUnifiedPayloadMessage() throws Exception {
        ChatStreamEvent event = ChatStreamEvent.error("session-1", "message-1", "boom");

        ServerSentEvent<String> sse = writer.toServerSentEvent(event);
        JsonNode data = objectMapper.readTree(sse.data());

        assertThat(sse.event()).isEqualTo("error");
        assertThat(data.get("type").asText()).isEqualTo("error");
        assertThat(data.get("payload").get("message").asText()).isEqualTo("boom");
    }
}
