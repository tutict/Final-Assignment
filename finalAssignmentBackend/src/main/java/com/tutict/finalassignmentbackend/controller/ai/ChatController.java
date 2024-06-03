package com.tutict.finalassignmentbackend.controller.ai;
import org.springframework.ai.bedrock.titan.BedrockTitanChatClient;
import org.springframework.ai.chat.ChatResponse;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
public class ChatController {

    @Autowired
    private BedrockTitanChatClient bedrockTitanChatClient;

    @GetMapping("/chat")
    public Flux<ChatResponse> chat(@RequestParam String message) {
        UserMessage userMessage = new UserMessage(message);
        Prompt prompt = new Prompt(userMessage);
        return bedrockTitanChatClient.stream(prompt);
    }
}
