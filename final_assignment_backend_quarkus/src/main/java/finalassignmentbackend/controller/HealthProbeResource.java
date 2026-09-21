package finalassignmentbackend.controller;

import jakarta.annotation.security.PermitAll;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Map;

@Path("/")
@PermitAll
public class HealthProbeResource {

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
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/actuator/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response actuator() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/actuator/health/liveness")
    @Produces(MediaType.APPLICATION_JSON)
    public Response actuatorLive() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/actuator/health/readiness")
    @Produces(MediaType.APPLICATION_JSON)
    public Response actuatorReady() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/api/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response apiHealth() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/api/actuator/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response apiActuator() {
        return Response.ok(Map.of("status", "UP")).build();
    }

    @GET
    @Path("/readyz")
    @Produces(MediaType.TEXT_PLAIN)
    public Response readyz() {
        return Response.ok("ok").build();
    }
}
