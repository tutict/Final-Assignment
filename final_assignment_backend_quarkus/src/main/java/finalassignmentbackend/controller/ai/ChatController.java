package finalassignmentbackend.controller.ai;

import finalassignmentbackend.service.ai.ChatService;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Response;
import io.smallrye.mutiny.Uni;

@Path("/ai")
public class ChatController {

    @Inject
    ChatService chatService;

    @GET
    @Path("/chat")
    public Uni<Response> chat(@QueryParam("message") String message) {
        return Uni.createFrom().item(() -> {
            try {
                String response = chatService.chat(message);
                return Response.ok(response).build();
            } catch (Exception e) {
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity("Chat failed: " + e.getMessage())
                        .build();
            }
        });
    }
}
