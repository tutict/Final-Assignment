package finalassignmentbackend.controller;

import finalassignmentbackend.entity.SysDict;
import finalassignmentbackend.entity.SysSettings;
import finalassignmentbackend.service.SysDictService;
import finalassignmentbackend.service.SysSettingsService;
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
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/api/system/settings")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "System Settings", description = "System settings and dict management")
public class SystemSettingsController {

    private static final Logger LOG = Logger.getLogger(SystemSettingsController.class.getName());

    @Inject
    SysSettingsService sysSettingsService;

    @Inject
    SysDictService sysDictService;

    @POST
    @RunOnVirtualThread
    public Response createSetting(SysSettings request,
                                  @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysSettingsService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                sysSettingsService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysSettings saved = sysSettingsService.createSysSettings(request);
            if (useKey && saved.getSettingId() != null) {
                sysSettingsService.markHistorySuccess(idempotencyKey, saved.getSettingId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                sysSettingsService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create setting failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{settingId}")
    @RunOnVirtualThread
    public Response updateSetting(@PathParam("settingId") Integer settingId,
                                  SysSettings request,
                                  @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setSettingId(settingId);
            if (useKey) {
                sysSettingsService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysSettings updated = sysSettingsService.updateSysSettings(request);
            if (useKey && updated.getSettingId() != null) {
                sysSettingsService.markHistorySuccess(idempotencyKey, updated.getSettingId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                sysSettingsService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update setting failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{settingId}")
    @RunOnVirtualThread
    public Response deleteSetting(@PathParam("settingId") Integer settingId) {
        try {
            sysSettingsService.deleteSysSettings(settingId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete setting failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{settingId}")
    @RunOnVirtualThread
    public Response getSetting(@PathParam("settingId") Integer settingId) {
        try {
            SysSettings settings = sysSettingsService.findById(settingId);
            return settings == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(settings).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get setting failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response listSettings() {
        try {
            return Response.ok(sysSettingsService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List settings failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/key/{settingKey}")
    @RunOnVirtualThread
    public Response getByKey(@PathParam("settingKey") String settingKey) {
        try {
            SysSettings settings = sysSettingsService.findByKey(settingKey);
            return settings == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(settings).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get setting by key failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/category/{category}")
    @RunOnVirtualThread
    public Response getByCategory(@PathParam("category") String category,
                                  @QueryParam("page") Integer page,
                                  @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 50 : size;
            return Response.ok(sysSettingsService.findByCategory(category, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List settings by category failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/key/prefix")
    @RunOnVirtualThread
    public Response searchByKeyPrefix(@QueryParam("settingKey") String settingKey,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysSettingsService.searchBySettingKeyPrefix(settingKey, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/key/fuzzy")
    @RunOnVirtualThread
    public Response searchByKeyFuzzy(@QueryParam("settingKey") String settingKey,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysSettingsService.searchBySettingKeyFuzzy(settingKey, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/type")
    @RunOnVirtualThread
    public Response searchByType(@QueryParam("settingType") String settingType,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysSettingsService.searchBySettingType(settingType, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/editable")
    @RunOnVirtualThread
    public Response searchByEditable(@QueryParam("isEditable") boolean isEditable,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysSettingsService.searchByIsEditable(isEditable, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/encrypted")
    @RunOnVirtualThread
    public Response searchByEncrypted(@QueryParam("isEncrypted") boolean isEncrypted,
                                      @QueryParam("page") Integer page,
                                      @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysSettingsService.searchByIsEncrypted(isEncrypted, resolvedPage, resolvedSize)).build();
    }

    @POST
    @Path("/dicts")
    @RunOnVirtualThread
    public Response createDict(SysDict request,
                               @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysDictService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                sysDictService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysDict saved = sysDictService.createSysDict(request);
            if (useKey && saved.getDictId() != null) {
                sysDictService.markHistorySuccess(idempotencyKey, saved.getDictId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                sysDictService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create dict failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/dicts/{dictId}")
    @RunOnVirtualThread
    public Response updateDict(@PathParam("dictId") Integer dictId,
                               SysDict request,
                               @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setDictId(dictId);
            if (useKey) {
                sysDictService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysDict updated = sysDictService.updateSysDict(request);
            if (useKey && updated.getDictId() != null) {
                sysDictService.markHistorySuccess(idempotencyKey, updated.getDictId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                sysDictService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update dict failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/dicts/{dictId}")
    @RunOnVirtualThread
    public Response deleteDict(@PathParam("dictId") Integer dictId) {
        try {
            sysDictService.deleteSysDict(dictId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete dict failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/dicts/{dictId}")
    @RunOnVirtualThread
    public Response getDict(@PathParam("dictId") Integer dictId) {
        try {
            SysDict dict = sysDictService.findById(dictId);
            return dict == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(dict).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get dict failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/dicts/search/type")
    @RunOnVirtualThread
    public Response searchDictByType(@QueryParam("dictType") String dictType,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysDictService.searchByDictType(dictType, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/dicts/search/code")
    @RunOnVirtualThread
    public Response searchDictByCode(@QueryParam("dictCode") String dictCode,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysDictService.searchByDictCodePrefix(dictCode, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/dicts/search/label/prefix")
    @RunOnVirtualThread
    public Response searchDictByLabelPrefix(@QueryParam("dictLabel") String dictLabel,
                                            @QueryParam("page") Integer page,
                                            @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysDictService.searchByDictLabelPrefix(dictLabel, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/dicts/search/label/fuzzy")
    @RunOnVirtualThread
    public Response searchDictByLabelFuzzy(@QueryParam("dictLabel") String dictLabel,
                                           @QueryParam("page") Integer page,
                                           @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysDictService.searchByDictLabelFuzzy(dictLabel, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/dicts/search/parent")
    @RunOnVirtualThread
    public Response searchDictByParent(@QueryParam("parentId") Integer parentId,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysDictService.findByParentId(parentId, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/dicts/search/default")
    @RunOnVirtualThread
    public Response searchDictByDefault(@QueryParam("isDefault") boolean isDefault,
                                        @QueryParam("page") Integer page,
                                        @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysDictService.searchByIsDefault(isDefault, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/dicts/search/status")
    @RunOnVirtualThread
    public Response searchDictByStatus(@QueryParam("status") String status,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 50 : size;
        return Response.ok(sysDictService.searchByStatus(status, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/dicts")
    @RunOnVirtualThread
    public Response listDicts() {
        try {
            return Response.ok(sysDictService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List dicts failed", ex);
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
