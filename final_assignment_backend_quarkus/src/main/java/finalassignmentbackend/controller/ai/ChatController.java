package finalassignmentbackend.controller.ai;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponses;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;
import org.springframework.ai.chat.client.ChatClient;

import java.util.logging.Logger;

@Path("/ai")
@Produces(MediaType.APPLICATION_JSON)
@Tag(name = "AI Chat", description = "Chat Controller for AI interactions")
public class ChatController {

    private static final Logger logger = Logger.getLogger(String.valueOf(ChatController.class));

    @Inject
    ChatClient chatClient;

    @GET
    @Path("/chat")
    @Operation(summary = "Chat with AI", description = "Provides an AI response based on user input")
    @APIResponses({
            @APIResponse(responseCode = "200", description = "Successful AI response"),
            @APIResponse(responseCode = "400", description = "Invalid input")
    })
    public String chat(@QueryParam("input") String input) {
        logger.info(String.format("User input: %s", input));
        return this.chatClient.prompt()
                .user(input)
                .call()
                .content();
    }
}
