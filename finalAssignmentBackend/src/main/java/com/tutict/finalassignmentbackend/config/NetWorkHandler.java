package com.tutict.finalassignmentbackend.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.login.JWT.TokenProvider;
import com.tutict.finalassignmentbackend.config.route.EventBusAddress;
import lombok.extern.slf4j.Slf4j;
import org.apache.camel.ProducerTemplate;
import org.jetbrains.annotations.NotNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.socket.CloseStatus;
import org.springframework.web.reactive.socket.WebSocketMessage;
import org.springframework.web.reactive.socket.WebSocketSession;
import org.springframework.web.reactive.socket.server.support.WebSocketHandlerAdapter;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Slf4j
@Component
public class NetWorkHandler implements org.springframework.web.reactive.socket.WebSocketHandler {

    // Configuration Properties
    @Value("${backend.url}")
    private String backendUrl;

    @Value("${backend.port}")
    private int backendPort;

    // Dependencies
    private final TokenProvider tokenProvider;
    private final ObjectMapper objectMapper;
    private final ProducerTemplate producerTemplate;
    private final WebClient webClient;

    // Constructor Injection
    public NetWorkHandler(TokenProvider tokenProvider,
                          ObjectMapper objectMapper,
                          ProducerTemplate producerTemplate,
                          WebClient.Builder webClientBuilder) {
        this.tokenProvider = tokenProvider;
        this.objectMapper = objectMapper;
        this.producerTemplate = producerTemplate;
        this.webClient = webClientBuilder.build();
    }

    /**
     * Bean to handle WebSocket connections
     */
    @Bean
    public WebSocketHandlerAdapter handlerAdapter() {
        return new WebSocketHandlerAdapter();
    }

    /**
     * Handle WebSocket connections
     */
    @NotNull
    @Override
    public Mono<Void> handle(WebSocketSession session) {
        String path = session.getHandshakeInfo().getUri().getPath();
        if (!path.startsWith("/eventbus")) {
            log.warn("Unsupported WebSocket path: {}", path);
            return session.close(CloseStatus.NORMAL.withReason("Unsupported path"));
        }

        return session.receive()
                .filter(msg -> msg.getType() == WebSocketMessage.Type.TEXT)
                .map(WebSocketMessage::getPayloadAsText)
                .flatMap(message -> processWebSocketMessage(message, session))
                .doOnError(error -> log.error("WebSocket processing error", error))
                .doFinally(signalType -> log.info("WebSocket connection closed: {}", signalType))
                .then();
    }

    /**
     * Process incoming WebSocket messages
     */
    private Mono<Void> processWebSocketMessage(String message, WebSocketSession session) {
        UUID requestId = UUID.randomUUID();
        try {
            JsonNode jsonNode = objectMapper.readTree(message);

            String token = jsonNode.has("token") ? jsonNode.get("token").asText() : null;

            if (token != null && tokenProvider.validateToken(token)) {
                String action = jsonNode.has("action") ? jsonNode.get("action").asText() : null;
                JsonNode data = jsonNode.has("data") ? jsonNode.get("data") : null;

                log.info("[{}] Received action: {}, with data: {}", requestId, action, data);

                producerTemplate.sendBodyAndHeader(
                        EventBusAddress.CLIENT_TO_SERVER,
                        data,
                        "RequestPath",
                        session.getHandshakeInfo().getUri().getPath()
                );

                return session.send(Mono.just(session.textMessage("Action received")))
                        .then();

            } else {
                log.warn("[{}] Invalid token, closing WebSocket connection", requestId);
                return session.close(CloseStatus.NORMAL.withReason("Invalid token"));
            }
        } catch (JsonProcessingException e) {
            log.error("[{}] Invalid JSON message, closing WebSocket connection", requestId, e);
            return session.close(CloseStatus.NORMAL.withReason("Invalid JSON format"));
        }
    }

    /**
     * 内部私有的 HTTP 转发控制器
     */
    @RestController
    @RequestMapping("/api")
    private class HttpForwardingController {

        /**
         * HTTP Request Forwarding Endpoint
         * This method handles all /api/** requests and forwards them to the backend service.
         */
        @PostMapping("/**")
        @GetMapping("/**")
        @PutMapping("/**")
        @RequestMapping(method = {RequestMethod.POST, RequestMethod.GET, RequestMethod.PUT})
        public Mono<ResponseEntity<String>> forwardRequest(@RequestBody(required = false) String body,
                                                           @RequestHeader HttpHeaders headers,
                                                           ServerWebExchange exchange) {
            String path = exchange.getRequest().getURI().getPath();
            String targetPath = path.replaceFirst("/api", ""); // Remove /api prefix
            String targetUrl = backendUrl + ":" + backendPort + targetPath;

            UUID requestId = UUID.randomUUID();
            log.info("[{}] Forwarding request from path: {} to targetUrl: {}", requestId, path, targetUrl);

            // Prevent forwarding loops
            if (headers.containsKey("X-Forwarded-By")) {
                log.error("[{}] Detected forwarding loop, terminating request processing", requestId);
                return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("循环转发"));
            }

            // Add custom header to identify forwarded requests
            HttpHeaders newHeaders = new HttpHeaders();
            newHeaders.add("X-Forwarded-By", "HttpForwardingController");

            if (body == null || body.isEmpty()) {
                log.error("[{}] Request body is empty, cannot send JSON data", requestId);
                return Mono.just(ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body("请求体为空"));
            }

            try {
                JsonNode jsonBody = objectMapper.readTree(body);
                log.info("[{}] Parsed JSON body: {}", requestId, jsonBody);

                return webClient.post()
                        .uri(targetUrl)
                        .headers(httpHeaders -> {
                            httpHeaders.addAll(newHeaders);
                            // Optionally, copy other headers as needed
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(jsonBody)
                        .exchangeToMono(response -> {
                            HttpStatusCode status = response.statusCode();
                            HttpHeaders responseHeaders = new HttpHeaders();
                            response.headers().asHttpHeaders().forEach((key, values) -> {
                                if (!key.equalsIgnoreCase("Transfer-Encoding")) {
                                    responseHeaders.put(key, values);
                                }
                            });

                            return response.bodyToMono(String.class)
                                    .map(bodyContent -> ResponseEntity.status(status)
                                            .headers(responseHeaders)
                                            .body(bodyContent));
                        })
                        .onErrorResume(error -> {
                            log.error("[{}] Forwarding HTTP request failed", requestId, error);
                            return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                    .body("转发失败"));
                        });

            } catch (JsonProcessingException e) {
                log.error("[{}] Failed to parse request body", requestId, e);
                return Mono.just(ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body("请求体解析失败"));
            }
        }
    }
}
