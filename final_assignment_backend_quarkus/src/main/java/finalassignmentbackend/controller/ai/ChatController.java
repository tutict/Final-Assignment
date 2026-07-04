package finalassignmentbackend.controller.ai;

import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.StreamingChatModel;
import dev.langchain4j.model.chat.request.ChatRequest;
import dev.langchain4j.model.chat.response.ChatResponse;
import dev.langchain4j.model.chat.response.StreamingChatResponseHandler;
import finalassignmentbackend.service.ai.AIChatSearchService;
import jakarta.annotation.security.RolesAllowed;
import io.smallrye.mutiny.Multi;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

import java.util.List;
import java.util.Map;
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
    @Produces(MediaType.SERVER_SENT_EVENTS)
    public Multi<String> chatStream(Map<String, Object> request) {
        String message = stringValue(request, "message");
        String massage = stringValue(request, "massage");
        boolean webSearch = booleanValue(request, "webSearch");
        return chat(message, massage, webSearch);
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
