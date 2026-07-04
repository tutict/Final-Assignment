package finalassignmentbackend.controller.rag;

import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.Map;

@Path("/api/rag/admin")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class RagManagementController {

    @GET
    @Path("/overview")
    @RunOnVirtualThread
    public Response overview() {
        return notImplemented("RAG admin overview is not implemented in the Quarkus backend yet.", Map.<String, Object>of("documents", 0, "pendingTasks", 0));
    }

    @GET
    @Path("/documents")
    @RunOnVirtualThread
    public Response documents() {
        return notImplemented("RAG document listing is not implemented in the Quarkus backend yet.", Map.<String, Object>of("documents", List.of()));
    }

    @POST
    @Path("/documents/manual")
    @RunOnVirtualThread
    public Response createManualDocument(Map<String, Object> request) {
        return notImplemented("Manual RAG document creation is not implemented in the Quarkus backend yet.", Map.of());
    }

    @POST
    @Path("/documents/upload")
    @Consumes("multipart/form-data")
    @RunOnVirtualThread
    public Response uploadDocument() {
        return notImplemented("RAG document upload is not implemented in the Quarkus backend yet.", Map.of());
    }

    @DELETE
    @Path("/documents/{documentId}")
    @RunOnVirtualThread
    public Response deleteDocument(@PathParam("documentId") Long documentId) {
        return notImplemented("RAG document deletion is not implemented in the Quarkus backend yet.", Map.<String, Object>of("documentId", documentId));
    }

    @POST
    @Path("/backfill")
    @RunOnVirtualThread
    public Response scheduleBackfill(Map<String, Object> request) {
        return notImplemented("RAG backfill scheduling is not implemented in the Quarkus backend yet.", Map.of());
    }

    @POST
    @Path("/backfill/run")
    @RunOnVirtualThread
    public Response runBackfill(Map<String, Object> request) {
        return notImplemented("RAG backfill run is not implemented in the Quarkus backend yet.", Map.of());
    }

    @POST
    @Path("/embedding/requeue")
    @RunOnVirtualThread
    public Response requeueEmbedding(Map<String, Object> request) {
        return notImplemented("RAG embedding requeue is not implemented in the Quarkus backend yet.", Map.of());
    }

    @POST
    @Path("/embedding/run")
    @RunOnVirtualThread
    public Response runEmbedding(Map<String, Object> request) {
        return notImplemented("RAG embedding run is not implemented in the Quarkus backend yet.", Map.of());
    }

    @POST
    @Path("/index/migrate")
    @RunOnVirtualThread
    public Response migrateIndex(Map<String, Object> request) {
        return notImplemented("RAG index migration is not implemented in the Quarkus backend yet.", Map.of());
    }

    private Response notImplemented(String message, Map<String, Object> extra) {
        java.util.LinkedHashMap<String, Object> payload = new java.util.LinkedHashMap<>();
        payload.put("code", "RAG_NOT_IMPLEMENTED");
        payload.put("message", message);
        payload.putAll(extra);
        return Response.status(Response.Status.NOT_IMPLEMENTED).entity(payload).build();
    }
}