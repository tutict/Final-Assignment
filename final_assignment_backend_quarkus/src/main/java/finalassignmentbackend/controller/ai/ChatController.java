package finalassignmentbackend.controller.ai;

import finalassignmentbackend.service.ai.ChatService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import io.smallrye.mutiny.Uni;

@Path("/ai")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ChatController {

    ChatService chatService;

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
