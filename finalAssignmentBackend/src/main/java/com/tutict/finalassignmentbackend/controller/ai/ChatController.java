package com.tutict.finalassignmentbackend.controller.ai;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/ai")
public class ChatController {
//
//    private final ChatClient chatClient;
//
//    @Autowired
//    public ChatController(ChatClient.Builder builder) {
//        this.chatClient = builder.build();
//    }
//
//    @GetMapping(value = "/steamChat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
//    public Flux<String> steamChat(@RequestParam String input) {
//        return chatClient.prompt()
//                .user(input)
//                .stream()
//                .content();
//    }
}