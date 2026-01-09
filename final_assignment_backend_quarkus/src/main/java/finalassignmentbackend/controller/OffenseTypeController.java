package finalassignmentbackend.controller;

import finalassignmentbackend.entity.OffenseTypeDict;
import finalassignmentbackend.service.OffenseTypeDictService;
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

import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/offense-types")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Offense Type Dictionary", description = "Offense type dictionary management")
public class OffenseTypeController {

    private static final Logger LOG = Logger.getLogger(OffenseTypeController.class.getName());

    @Inject
    OffenseTypeDictService offenseTypeDictService;

    @POST
    @RunOnVirtualThread
    public Response create(OffenseTypeDict request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (offenseTypeDictService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                offenseTypeDictService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            OffenseTypeDict saved = offenseTypeDictService.createDict(request);
            if (useKey && saved.getTypeId() != null) {
                offenseTypeDictService.markHistorySuccess(idempotencyKey, saved.getTypeId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                offenseTypeDictService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create offense type failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{typeId}")
    @RunOnVirtualThread
    public Response update(@PathParam("typeId") Integer typeId,
                           OffenseTypeDict request,
                           @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setTypeId(typeId);
            if (useKey) {
                offenseTypeDictService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            OffenseTypeDict updated = offenseTypeDictService.updateDict(request);
            if (useKey && updated.getTypeId() != null) {
                offenseTypeDictService.markHistorySuccess(idempotencyKey, updated.getTypeId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                offenseTypeDictService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update offense type failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{typeId}")
    @RunOnVirtualThread
    public Response delete(@PathParam("typeId") Integer typeId) {
        try {
            offenseTypeDictService.deleteDict(typeId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete offense type failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{typeId}")
    @RunOnVirtualThread
    public Response get(@PathParam("typeId") Integer typeId) {
        try {
            OffenseTypeDict dict = offenseTypeDictService.findById(typeId);
            return dict == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(dict).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get offense type failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response list() {
        try {
            return Response.ok(offenseTypeDictService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offense types failed", ex);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GET
    @Path("/search/code/prefix")
    @RunOnVirtualThread
    public Response searchByCodePrefix(@QueryParam("offenseCode") String offenseCode,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchByOffenseCodePrefix(offenseCode, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/code/fuzzy")
    @RunOnVirtualThread
    public Response searchByCodeFuzzy(@QueryParam("offenseCode") String offenseCode,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchByOffenseCodeFuzzy(offenseCode, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/name/prefix")
    @RunOnVirtualThread
    public Response searchByNamePrefix(@QueryParam("offenseName") String offenseName,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchByOffenseNamePrefix(offenseName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/name/fuzzy")
    @RunOnVirtualThread
    public Response searchByNameFuzzy(@QueryParam("offenseName") String offenseName,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchByOffenseNameFuzzy(offenseName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/category")
    @RunOnVirtualThread
    public Response searchByCategory(@QueryParam("category") String category,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchByCategory(category, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/severity")
    @RunOnVirtualThread
    public Response searchBySeverity(@QueryParam("severityLevel") String severityLevel,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchBySeverityLevel(severityLevel, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response searchByStatus(@QueryParam("status") String status,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchByStatus(status, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/fine-range")
    @RunOnVirtualThread
    public Response searchByFineRange(@QueryParam("minAmount") double minAmount,
                                      @QueryParam("maxAmount") double maxAmount,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchByStandardFineAmountRange(minAmount, maxAmount, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/points-range")
    @RunOnVirtualThread
    public Response searchByPointsRange(@QueryParam("minPoints") int minPoints,
                                        @QueryParam("maxPoints") int maxPoints,
                                        @QueryParam("page") Integer page,
                                        @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(offenseTypeDictService.searchByDeductedPointsRange(minPoints, maxPoints, resolvedPage, resolvedSize)).build();
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
