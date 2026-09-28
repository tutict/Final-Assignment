package finalassignmentbackend.controller;

import io.agroal.api.AgroalDataSource;
import jakarta.annotation.security.PermitAll;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.sql.Connection;
import java.util.Map;

@Path("/")
@PermitAll
public class HealthProbeResource {

    @Inject
    AgroalDataSource dataSource;

    @GET
    @Path("/q/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response health() {
        return database();
    }

    @GET
    @Path("/q/health/live")
    @Produces(MediaType.APPLICATION_JSON)
    public Response live() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/q/health/ready")
    @Produces(MediaType.APPLICATION_JSON)
    public Response ready() {
        return database();
    }

    @GET
    @Path("/actuator/health/liveness")
    @Produces(MediaType.APPLICATION_JSON)
    public Response actuatorLive() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/api/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response apiHealth() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/readyz")
    @Produces(MediaType.TEXT_PLAIN)
    public Response readyz() {
        return databaseUp() ? Response.ok("ok").build() : Response.status(Response.Status.SERVICE_UNAVAILABLE).entity("down").build();
    }

    private Response database() {
        if (databaseUp()) {
            return Response.ok(Map.of("status", "UP")).build();
        }
        return Response.status(Response.Status.SERVICE_UNAVAILABLE).entity(Map.of("status", "DOWN")).build();
    }

    private boolean databaseUp() {
        try (Connection connection = dataSource.getConnection()) {
            return connection.isValid(1);
        } catch (Exception ignored) {
            return false;
        }
    }
}
