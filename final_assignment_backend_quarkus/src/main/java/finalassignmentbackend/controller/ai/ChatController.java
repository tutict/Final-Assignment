package finalassignmentbackend.controller.ai;

import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.StreamingChatModel;
import dev.langchain4j.model.chat.request.ChatRequest;
import dev.langchain4j.model.chat.response.ChatResponse;
import dev.langchain4j.model.chat.response.StreamingChatResponseHandler;
import finalassignmentbackend.ai.agent.AgentModels;
import finalassignmentbackend.ai.agent.AgentRuntime;
import finalassignmentbackend.controller.DriverAccessGuard;
import finalassignmentbackend.service.ai.AIChatSearchService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.annotation.security.RolesAllowed;
import io.smallrye.mutiny.Multi;
import jakarta.inject.Inject;
import jakarta.json.bind.Jsonb;
import jakarta.json.bind.JsonbBuilder;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/ai")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER", "USER"})
public class ChatController {

    private static final Logger LOG = Logger.getLogger(ChatController.class.getName());

    @Inject
    StreamingChatModel chatModel;

    @Inject
    AIChatSearchService aiChatSearchService;
    @Inject AgentRuntime agentRuntime;
    @Inject DriverAccessGuard driverAccessGuard;
    private final Jsonb jsonb = JsonbBuilder.create();

    @GET
    @Path("/chat")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    public Multi<String> chat(
            @QueryParam("message") String message,
            @QueryParam("massage") String massage,
            @QueryParam("webSearch") @DefaultValue("false") boolean webSearch) {
        String userMessage = resolveMessage(message, massage);
        if (userMessage.isBlank()) {
            throw new IllegalArgumentException("Either message or massage must be provided");
        }
        if (massage != null && !massage.isBlank()) {
            LOG.warning("Deprecated query parameter 'massage' was used; prefer 'message'.");
        }

        String promptText = buildPrompt(userMessage, webSearch);
        ChatRequest request = ChatRequest.builder()
                .messages(UserMessage.from(promptText))
                .build();

        return Multi.createFrom().emitter(emitter -> chatModel.chat(request, new StreamingChatResponseHandler() {
            @Override
            public void onPartialResponse(String partialResponse) {
                emitter.emit(partialResponse);
            }

            @Override
            public void onCompleteResponse(ChatResponse completeResponse) {
                emitter.complete();
                LOG.log(Level.INFO, "AI chat stream completed");
            }

            @Override
            public void onError(Throwable error) {
                emitter.fail(error);
                LOG.log(Level.SEVERE, "AI chat stream failed", error);
            }
        }));
    }

    @POST
    @Path("/chat/stream")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces("text/event-stream")
    @RunOnVirtualThread
    public Response chatStream(@Context SecurityContext securityContext, Map<String, Object> request) {
        String message = stringValue(request, "message");
        String massage = stringValue(request, "massage");
        boolean webSearch = booleanValue(request, "webSearch");
        String userMessage = resolveMessage(message, massage);
        String sessionKey = stringValue(request, "sessionKey");
        if (sessionKey == null || sessionKey.isBlank()) sessionKey = UUID.randomUUID().toString();
        String username = securityContext != null && securityContext.getUserPrincipal() != null ? securityContext.getUserPrincipal().getName() : "anonymous";
        String role = "USER";
        if (securityContext != null) {
            if (securityContext.isUserInRole("SUPER_ADMIN")) role = "SUPER_ADMIN";
            else if (securityContext.isUserInRole("ADMIN")) role = "ADMIN";
            else if (securityContext.isUserInRole("USER") || securityContext.isUserInRole("DRIVER")) role = "USER";
        }
        Long driverId = driverAccessGuard.currentDriverId(securityContext);
        StringBuilder sse = new StringBuilder();
        if (!agentRuntime.bindSession(username, sessionKey)) {
            sse.append("data: ").append(jsonb.toJson(Map.of("type", "error", "sessionKey", sessionKey, "payload", Map.of("message", "不能使用其他用户的会话"), "timestamp", Instant.now().toString()))).append("\n\n");
            return Response.ok(sse.toString()).type("text/event-stream;charset=UTF-8").build();
        }
        AgentModels.Context context = new AgentModels.Context(role, sessionKey, username, username, driverId, false);
        List<String> prefix = new ArrayList<>();
        for (Map<String, Object> event : agentRuntime.execute(userMessage, context)) {
            prefix.add(jsonb.toJson(event));
        }
        for (String json : prefix) {
            sse.append("data: ").append(json).append("\n\n");
        }
        String done = jsonb.toJson(Map.of("type", "done", "sessionKey", sessionKey, "timestamp", Instant.now().toString()));
        boolean skipModel = prefix.stream().anyMatch(json -> json.contains("\"type\":\"draft\"") || json.contains("\"type\":\"result\"") || json.contains("\"type\":\"error\""));
        if (!skipModel) {
            try {
                List<String> tokens = chat(userMessage, null, webSearch).collect().asList().await().atMost(Duration.ofSeconds(45));
                for (String token : tokens) {
                    sse.append("data: ").append(jsonb.toJson(tokenEvent(sessionKey, token))).append("\n\n");
                }
            } catch (RuntimeException ex) {
                sse.append("data: ").append(jsonb.toJson(Map.of("type", "error", "sessionKey", sessionKey, "payload", Map.of("message", "模型生成失败"), "timestamp", Instant.now().toString()))).append("\n\n");
            }
        }
        sse.append("data: ").append(done).append("\n\n");
        return Response.ok(sse.toString()).type("text/event-stream;charset=UTF-8").build();
    }

    private static Map<String, Object> tokenEvent(String sessionKey, String token) {
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("type", "token");
        event.put("sessionKey", sessionKey);
        event.put("token", token);
        event.put("timestamp", Instant.now().toString());
        return event;
    }

    @GET
    @Path("/chat/actions")
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, Object> getChatActions(
            @QueryParam("message") String message,
            @QueryParam("massage") String massage,
            @QueryParam("webSearch") @DefaultValue("false") boolean webSearch) {
        String userMessage = resolveMessage(message, massage);
        String answer = userMessage.isBlank()
                ? "Please provide message or massage."
                : "Quarkus AI chat route is available; action suggestions are not implemented yet.";
        return Map.of(
                "answer", answer,
                "actions", List.of(),
                "needConfirm", false,
                "webSearch", webSearch
        );
    }

    private String buildPrompt(String userMessage, boolean webSearch) {
        StringBuilder promptBuilder = new StringBuilder()
                .append("You are a professional traffic violation query assistant. Answer in concise, accurate Chinese with structured bullets where useful.\n\n");

        if (webSearch) {
            List<Map<String, String>> results = aiChatSearchService.search(userMessage);
            promptBuilder.append("Search results:\n")
                    .append(formatSearchResults(results))
                    .append('\n');
        }

        return promptBuilder.append("User question: ").append(userMessage).toString();
    }

    private static String resolveMessage(String message, String massage) {
        return message != null && !message.isBlank() ? message : (massage == null ? "" : massage);
    }

    private static String stringValue(Map<String, Object> request, String key) {
        if (request == null || request.get(key) == null) {
            return null;
        }
        return String.valueOf(request.get(key));
    }

    private static boolean booleanValue(Map<String, Object> request, String key) {
        if (request == null || request.get(key) == null) {
            return false;
        }
        Object value = request.get(key);
        return value instanceof Boolean bool ? bool : Boolean.parseBoolean(String.valueOf(value));
    }

    private static String formatSearchResults(List<Map<String, String>> results) {
        if (results == null || results.isEmpty()) {
            return "No relevant search results found.";
        }
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < results.size(); i++) {
            Map<String, String> item = results.get(i);
            builder.append(i + 1)
                    .append(". ")
                    .append(item.getOrDefault("title", "Untitled"))
                    .append("\n   ")
                    .append(item.getOrDefault("abstract", "No summary"))
                    .append('\n');
        }
        return builder.toString();
    }
}
