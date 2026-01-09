package finalassignmentbackend.controller;

import finalassignmentbackend.entity.AppealRecord;
import finalassignmentbackend.entity.AppealReview;
import finalassignmentbackend.service.AppealManagementService;
import finalassignmentbackend.service.AppealReviewService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/appeals")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Appeal Management", description = "Appeal Management Controller for managing appeals")
public class AppealManagementController {

    private static final Logger LOG = Logger.getLogger(AppealManagementController.class.getName());

    @Inject
    AppealManagementService appealManagementService;

    @Inject
    AppealReviewService appealReviewService;

    @POST
    @RunOnVirtualThread
    public Response createAppeal(AppealRecord request,
                                 @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (appealManagementService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                appealManagementService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            AppealRecord saved = appealManagementService.createAppeal(request);
            if (useKey && saved.getAppealId() != null) {
                appealManagementService.markHistorySuccess(idempotencyKey, saved.getAppealId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                appealManagementService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create appeal failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{appealId}")
    @RunOnVirtualThread
    public Response updateAppeal(@PathParam("appealId") Long appealId,
                                 AppealRecord request,
                                 @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setAppealId(appealId);
            if (useKey) {
                appealManagementService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            AppealRecord updated = appealManagementService.updateAppeal(request);
            if (useKey && updated.getAppealId() != null) {
                appealManagementService.markHistorySuccess(idempotencyKey, updated.getAppealId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                appealManagementService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update appeal failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{appealId}")
    @RunOnVirtualThread
    public Response deleteAppeal(@PathParam("appealId") Long appealId) {
        try {
            appealManagementService.deleteAppeal(appealId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete appeal failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{appealId}")
    @RunOnVirtualThread
    public Response getAppeal(@PathParam("appealId") Long appealId) {
        try {
            AppealRecord record = appealManagementService.getAppealById(appealId);
            return record == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(record).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get appeal failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response listAppeals(@QueryParam("offenseId") Long offenseId,
                                @QueryParam("page") Integer page,
                                @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(appealManagementService.findByOffenseId(offenseId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List appeals failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/number/prefix")
    @RunOnVirtualThread
    public Response searchByNumberPrefix(@QueryParam("appealNumber") String appealNumber,
                                         @QueryParam("page") Integer page,
                                         @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByAppealNumberPrefix(appealNumber, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/number/fuzzy")
    @RunOnVirtualThread
    public Response searchByNumberFuzzy(@QueryParam("appealNumber") String appealNumber,
                                        @QueryParam("page") Integer page,
                                        @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByAppealNumberFuzzy(appealNumber, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/appellant/name/prefix")
    @RunOnVirtualThread
    public Response searchByAppellantNamePrefix(@QueryParam("appellantName") String appellantName,
                                                @QueryParam("page") Integer page,
                                                @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByAppellantNamePrefix(appellantName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/appellant/name/fuzzy")
    @RunOnVirtualThread
    public Response searchByAppellantNameFuzzy(@QueryParam("appellantName") String appellantName,
                                               @QueryParam("page") Integer page,
                                               @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByAppellantNameFuzzy(appellantName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/appellant/id-card")
    @RunOnVirtualThread
    public Response searchByAppellantIdCard(@QueryParam("appellantIdCard") String appellantIdCard,
                                            @QueryParam("page") Integer page,
                                            @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByAppellantIdCard(appellantIdCard, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/acceptance-status")
    @RunOnVirtualThread
    public Response searchByAcceptanceStatus(@QueryParam("acceptanceStatus") String acceptanceStatus,
                                             @QueryParam("page") Integer page,
                                             @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByAcceptanceStatus(acceptanceStatus, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/process-status")
    @RunOnVirtualThread
    public Response searchByProcessStatus(@QueryParam("processStatus") String processStatus,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByProcessStatus(processStatus, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/time-range")
    @RunOnVirtualThread
    public Response searchByTimeRange(@QueryParam("startTime") String startTime,
                                      @QueryParam("endTime") String endTime,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByAppealTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/handler")
    @RunOnVirtualThread
    public Response searchByHandler(@QueryParam("acceptanceHandler") String acceptanceHandler,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealManagementService.searchByAcceptanceHandler(acceptanceHandler, resolvedPage, resolvedSize)).build();
    }

    @POST
    @Path("/{appealId}/reviews")
    @RunOnVirtualThread
    public Response createReview(@PathParam("appealId") Long appealId,
                                 AppealReview review,
                                 @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            review.setAppealId(appealId);
            if (useKey) {
                if (appealReviewService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                appealReviewService.checkAndInsertIdempotency(idempotencyKey, review, "create");
            }
            AppealReview saved = appealReviewService.createReview(review);
            if (useKey && saved.getReviewId() != null) {
                appealReviewService.markHistorySuccess(idempotencyKey, saved.getReviewId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                appealReviewService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create appeal review failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/reviews/{reviewId}")
    @RunOnVirtualThread
    public Response updateReview(@PathParam("reviewId") Long reviewId,
                                 AppealReview review,
                                 @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            review.setReviewId(reviewId);
            if (useKey) {
                appealReviewService.checkAndInsertIdempotency(idempotencyKey, review, "update");
            }
            AppealReview updated = appealReviewService.updateReview(review);
            if (useKey && updated.getReviewId() != null) {
                appealReviewService.markHistorySuccess(idempotencyKey, updated.getReviewId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                appealReviewService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update appeal review failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/reviews/{reviewId}")
    @RunOnVirtualThread
    public Response deleteReview(@PathParam("reviewId") Long reviewId) {
        try {
            appealReviewService.deleteReview(reviewId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete appeal review failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/reviews/{reviewId}")
    @RunOnVirtualThread
    public Response getReview(@PathParam("reviewId") Long reviewId) {
        try {
            AppealReview review = appealReviewService.findById(reviewId);
            return review == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(review).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get appeal review failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/reviews")
    @RunOnVirtualThread
    public Response listReviews() {
        try {
            return Response.ok(appealReviewService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List appeal reviews failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/reviews/search/reviewer")
    @RunOnVirtualThread
    public Response searchReviewsByReviewer(@QueryParam("reviewer") String reviewer,
                                            @QueryParam("page") Integer page,
                                            @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealReviewService.searchByReviewer(reviewer, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/reviews/search/reviewer-dept")
    @RunOnVirtualThread
    public Response searchReviewsByReviewerDept(@QueryParam("reviewerDept") String reviewerDept,
                                                @QueryParam("page") Integer page,
                                                @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealReviewService.searchByReviewerDept(reviewerDept, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/reviews/search/time-range")
    @RunOnVirtualThread
    public Response searchReviewsByTimeRange(@QueryParam("startTime") String startTime,
                                             @QueryParam("endTime") String endTime,
                                             @QueryParam("page") Integer page,
                                             @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(appealReviewService.searchByReviewTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/reviews/count")
    @RunOnVirtualThread
    public Response countReviews(@QueryParam("level") String reviewLevel) {
        try {
            long total = appealReviewService.countByReviewLevel(reviewLevel);
            return Response.ok(Map.of("reviewLevel", reviewLevel, "count", total)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Count appeal reviews failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private Response.Status resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? Response.Status.BAD_REQUEST
                : Response.Status.INTERNAL_SERVER_ERROR;
    }
}
