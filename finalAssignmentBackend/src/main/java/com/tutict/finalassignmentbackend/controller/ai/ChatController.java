package com.tutict.finalassignmentbackend.controller.ai;

import org.json.JSONObject;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.List;

@RestController
@RequestMapping("/api/ai")
public class ChatController {

    private static final Logger LOG = Logger.getLogger(ChatController.class.getName());
    private final ChatClient chatClient;

    public ChatController(ChatClient.Builder chatClient) {
        this.chatClient = chatClient.build();
    }

    @RequestMapping(
            value = "/chat",
            produces = "application/json;charset=UTF-8"
    )
    public ResponseEntity<String> chat(@RequestParam(value = "massage") String message) {
        try {
            Flux<String> responseFlux = chatClient.prompt(message).stream().content();
            StringBuilder responseBuilder = new StringBuilder();

            List<String> responseList = responseFlux.collectList().block();
            if (responseList != null && !responseList.isEmpty()) {
                responseList.forEach(responseBuilder::append);
            } else {
                responseBuilder.append("AI 未返回有效响应，请稍后重试。");
                LOG.log(Level.WARNING, "Empty or null response from AI for message: " + message);
            }

            String responseStr = responseBuilder.toString()
                    .replaceAll("(?s)<think>.*?</think>", "")
                    .trim();

            String jsonResponse = "{\"message\": " + JSONObject.quote(responseStr) + "}";
            return ResponseEntity.ok()
                    .header("Content-Type", "application/json; charset=UTF-8")
                    .body(jsonResponse);
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Chat failed: " + e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .header("Content-Type", "application/json; charset=UTF-8")
                    .body("{\"error\": \"Chat failed: " + e.getMessage() + "\"}");
        }
    }
}