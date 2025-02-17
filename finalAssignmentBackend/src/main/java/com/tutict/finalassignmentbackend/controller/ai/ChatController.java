package com.tutict.finalassignmentbackend.controller.ai;

import org.junit.platform.commons.logging.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/ai")
public class ChatController {

    Logger logger = (Logger) LoggerFactory.getLogger(ChatController.class);

    private final ChatClient chatClient;

    public ChatController(ChatClient.Builder chatClient) {
        this.chatClient = chatClient.build();
    }

    @RequestMapping("/chat")
    public ResponseEntity<Flux<String>> chat(@RequestParam(value = "massage") String message) {
        try {
            Flux<String> response = chatClient.prompt(message).stream().content();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.log(Level.WARNING, "Chat failed: " + e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }
}