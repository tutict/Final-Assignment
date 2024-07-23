package finalassignmentbackend.controller.ai;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/eventbus/")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ChatController {

    BedrockTitanChatClient bedrockTitanChatClient;

    @GetMapping("/chat")
    public Flux<ChatResponse> chat(@RequestParam String message) {
        UserMessage userMessage = new UserMessage(message);
        Prompt prompt = new Prompt(userMessage);
        return bedrockTitanChatClient.stream(prompt);
    }
}
