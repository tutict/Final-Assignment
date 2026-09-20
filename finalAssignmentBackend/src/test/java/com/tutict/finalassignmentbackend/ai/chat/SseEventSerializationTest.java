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

    @Test
    void serializesQueueEventWithPosition() throws Exception {
        ServerSentEvent<String> sse = writer.toServerSentEvent(
                ChatStreamEvent.queue("session-1", "message-1", 2)
        );
        JsonNode data = objectMapper.readTree(sse.data());
        assertThat(sse.event()).isEqualTo("queue");
        assertThat(data.get("type").asText()).isEqualTo("queue");
        assertThat(data.get("payload").get("position").asInt()).isEqualTo(2);
    }

    @Test
    void serializesDraftResultToolAndActionEvents() throws Exception {
        StreamEventWriter writer = new StreamEventWriter(objectMapper);
        var draft = writer.toServerSentEvent(ChatStreamEvent.payload(
                ChatStreamEventType.DRAFT.wireName(), "session-1", "message-1",
                java.util.Map.of("draftId", "d1", "summary", "请确认")
        ));
        var result = writer.toServerSentEvent(ChatStreamEvent.payload(
                ChatStreamEventType.RESULT.wireName(), "session-1", "message-1",
                java.util.Map.of("summary", "共找到 1 条")
        ));
        var tool = writer.toServerSentEvent(ChatStreamEvent.payload(
                ChatStreamEventType.TOOL.wireName(), "session-1", "message-1",
                java.util.Map.of("phase", "start", "name", "query_my_offenses")
        ));
        var action = writer.toServerSentEvent(ChatStreamEvent.payload(
                ChatStreamEventType.ACTION.wireName(), "session-1", "message-1",
                java.util.Map.of("type", "NAVIGATE", "target", "/userOffenseListPage")
        ));
        assertThat(draft.event()).isEqualTo("draft");
        assertThat(result.event()).isEqualTo("result");
        assertThat(tool.event()).isEqualTo("tool");
        assertThat(action.event()).isEqualTo("action");
    }
}
