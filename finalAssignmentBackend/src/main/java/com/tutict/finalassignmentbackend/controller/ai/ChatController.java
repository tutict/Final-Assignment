package com.tutict.finalassignmentbackend.controller.ai;

import com.tutict.finalassignmentbackend.model.ai.ChatActionResponse;
import com.tutict.finalassignmentbackend.model.ai.ChatRequest;
import com.tutict.finalassignmentbackend.service.ChatAgent;
import jakarta.validation.Valid;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/api/ai")
public class ChatController {

    private final ChatAgent chatAgent;

    public ChatController(ChatAgent chatAgent) {
        this.chatAgent = chatAgent;
    }

    @PostMapping(
            value = "/chat",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.TEXT_EVENT_STREAM_VALUE
    )
    public Flux<ChatResponse> chat(@Valid @RequestBody ChatRequest request) {
        return chatAgent.streamChat(request.message(), request.massage(), request.webSearch());
    }

    @GetMapping(value = "/chat/actions", produces = MediaType.APPLICATION_JSON_VALUE)
    public ChatActionResponse chatActions(
            @RequestParam(value = "message", required = false) String message,
            @RequestParam(value = "massage", required = false) String massage,
            @RequestParam(value = "webSearch", defaultValue = "false") boolean webSearch) {
        return chatAgent.chatWithActions(message, massage, webSearch);
    }
}
