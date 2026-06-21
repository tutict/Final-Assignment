package com.tutict.finalassignmentcloud.ai.chat;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.ai.chat.response.ChatStreamEvent;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;

@Component
public class StreamEventWriter {

    private final ObjectMapper objectMapper;

    public StreamEventWriter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public Flux<ServerSentEvent<String>> write(Flux<ChatStreamEvent> events) {
        return events.map(this::toServerSentEvent);
    }

    public ServerSentEvent<String> toServerSentEvent(ChatStreamEvent event) {
        try {
            return ServerSentEvent.<String>builder(objectMapper.writeValueAsString(event))
                    .event(event.type())
                    .build();
        } catch (JsonProcessingException ex) {
            return ServerSentEvent.<String>builder(
                            "{\"type\":\"error\",\"payload\":{\"message\":\"SSE serialization failed\"}}"
                    )
                    .event(ChatStreamEventType.ERROR.wireName())
                    .build();
        }
    }
}
