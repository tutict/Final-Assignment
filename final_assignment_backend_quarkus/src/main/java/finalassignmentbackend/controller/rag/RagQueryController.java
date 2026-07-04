package finalassignmentbackend.controller.rag;

import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.Map;

@Path("/api/rag")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class RagQueryController {

    @POST
    @Path("/query")
    @RunOnVirtualThread
    public Response query(Map<String, Object> request) {
        return notImplemented("RAG query is not implemented in the Quarkus backend yet.", Map.<String, Object>of("results", List.of()));
    }

    private Response notImplemented(String message, Map<String, Object> extra) {
        java.util.LinkedHashMap<String, Object> payload = new java.util.LinkedHashMap<>();
        payload.put("code", "RAG_NOT_IMPLEMENTED");
        payload.put("message", message);
        payload.putAll(extra);
        return Response.status(Response.Status.NOT_IMPLEMENTED).entity(payload).build();
    }
}