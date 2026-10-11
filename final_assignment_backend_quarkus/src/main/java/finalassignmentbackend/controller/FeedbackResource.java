package finalassignmentbackend.controller;

import finalassignmentbackend.service.business.ConsultationFeedbackService;
import finalassignmentbackend.service.business.ConsultationFeedbackService.FeedbackRequestException;
import finalassignmentbackend.service.business.ConsultationFeedbackService.SavedFeedback;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;

import java.util.Map;

@Path("/api/feedback")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class FeedbackResource {

    @Inject
    ConsultationFeedbackService feedbackService;

    @GET
    public Response list(@Context SecurityContext securityContext) throws Exception {
        try {
            return Response.ok(feedbackService.list(username(securityContext), isStaff(securityContext))).build();
        } catch (FeedbackRequestException ex) {
            return error(ex);
        }
    }

    @POST
    public Response create(Map<String, Object> body,
                           @HeaderParam("Idempotency-Key") String idempotencyKey,
                           @Context SecurityContext securityContext) throws Exception {
        try {
            SavedFeedback saved = feedbackService.create(
                    username(securityContext), isStaff(securityContext), body, idempotencyKey);
            if (saved.created()) {
                return Response.status(Response.Status.CREATED).entity(saved.body()).build();
            }
            return Response.ok(saved.body()).build();
        } catch (FeedbackRequestException ex) {
            return error(ex);
        }
    }

    @PUT
    @Path("/{feedbackId}")
    public Response update(@PathParam("feedbackId") long feedbackId,
                           Map<String, Object> body,
                           @Context SecurityContext securityContext) throws Exception {
        try {
            return Response.ok(feedbackService.update(
                    username(securityContext), isStaff(securityContext), feedbackId, body)).build();
        } catch (FeedbackRequestException ex) {
            return error(ex);
        }
    }

    private static Response error(FeedbackRequestException ex) {
        return Response.status(ex.status())
                .entity(Map.of("errorCode", ex.code(), "message", ex.getMessage()))
                .build();
    }

    private static String username(SecurityContext securityContext) {
        if (securityContext == null || securityContext.getUserPrincipal() == null) {
            return "";
        }
        return securityContext.getUserPrincipal().getName();
    }

    private static boolean isStaff(SecurityContext securityContext) {
        return securityContext != null && (securityContext.isUserInRole("ADMIN")
                || securityContext.isUserInRole("SUPER_ADMIN")
                || securityContext.isUserInRole("ROLE_ADMIN")
                || securityContext.isUserInRole("ROLE_SUPER_ADMIN"));
    }
}
