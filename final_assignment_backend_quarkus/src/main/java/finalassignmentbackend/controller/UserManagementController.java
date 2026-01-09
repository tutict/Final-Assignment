package finalassignmentbackend.controller;

import finalassignmentbackend.entity.SysUser;
import finalassignmentbackend.entity.SysUserRole;
import finalassignmentbackend.service.SysUserRoleService;
import finalassignmentbackend.service.SysUserService;
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

@Path("/api/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "User Management", description = "System user management")
public class UserManagementController {

    private static final Logger LOG = Logger.getLogger(UserManagementController.class.getName());

    @Inject
    SysUserService sysUserService;

    @Inject
    SysUserRoleService sysUserRoleService;

    @POST
    @RunOnVirtualThread
    public Response createUser(SysUser request,
                               @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysUserService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                sysUserService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysUser saved = sysUserService.createSysUser(request);
            if (useKey && saved.getUserId() != null) {
                sysUserService.markHistorySuccess(idempotencyKey, saved.getUserId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                sysUserService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create user failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/{userId}")
    @RunOnVirtualThread
    public Response updateUser(@PathParam("userId") Long userId,
                               SysUser request,
                               @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            request.setUserId(userId);
            if (useKey) {
                sysUserService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            SysUser updated = sysUserService.updateSysUser(request);
            if (useKey && updated.getUserId() != null) {
                sysUserService.markHistorySuccess(idempotencyKey, updated.getUserId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                sysUserService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update user failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/{userId}")
    @RunOnVirtualThread
    public Response deleteUser(@PathParam("userId") Long userId) {
        try {
            sysUserService.deleteSysUser(userId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete user failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{userId}")
    @RunOnVirtualThread
    public Response getUser(@PathParam("userId") Long userId) {
        try {
            SysUser user = sysUserService.findById(userId);
            return user == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(user).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get user failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @RunOnVirtualThread
    public Response listUsers() {
        try {
            return Response.ok(sysUserService.findAll()).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/username/{username}")
    @RunOnVirtualThread
    public Response getByUsername(@PathParam("username") String username) {
        try {
            SysUser user = sysUserService.findByUsername(username);
            return user == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(user).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get user by username failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/username/prefix")
    @RunOnVirtualThread
    public Response searchByUsernamePrefix(@QueryParam("username") String username,
                                           @QueryParam("page") Integer page,
                                           @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByUsernamePrefix(username, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/username/fuzzy")
    @RunOnVirtualThread
    public Response searchByUsernameFuzzy(@QueryParam("username") String username,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByUsernameFuzzy(username, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/real-name/prefix")
    @RunOnVirtualThread
    public Response searchByRealNamePrefix(@QueryParam("realName") String realName,
                                           @QueryParam("page") Integer page,
                                           @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByRealNamePrefix(realName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/real-name/fuzzy")
    @RunOnVirtualThread
    public Response searchByRealNameFuzzy(@QueryParam("realName") String realName,
                                          @QueryParam("page") Integer page,
                                          @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByRealNameFuzzy(realName, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/id-card")
    @RunOnVirtualThread
    public Response searchByIdCard(@QueryParam("idCardNumber") String idCardNumber,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByIdCardNumber(idCardNumber, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/contact")
    @RunOnVirtualThread
    public Response searchByContact(@QueryParam("contactNumber") String contactNumber,
                                    @QueryParam("page") Integer page,
                                    @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByContactNumber(contactNumber, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/status")
    @RunOnVirtualThread
    public Response listByStatus(@QueryParam("status") String status,
                                 @QueryParam("page") Integer page,
                                 @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(sysUserService.findByStatus(status, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users by status failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/department")
    @RunOnVirtualThread
    public Response listByDepartment(@QueryParam("department") String department,
                                     @QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(sysUserService.findByDepartment(department, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users by department failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/search/department/prefix")
    @RunOnVirtualThread
    public Response searchByDepartmentPrefix(@QueryParam("department") String department,
                                             @QueryParam("page") Integer page,
                                             @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByDepartmentPrefix(department, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/employee-number")
    @RunOnVirtualThread
    public Response searchByEmployeeNumber(@QueryParam("employeeNumber") String employeeNumber,
                                           @QueryParam("page") Integer page,
                                           @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByEmployeeNumber(employeeNumber, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/search/last-login-range")
    @RunOnVirtualThread
    public Response searchByLastLoginRange(@QueryParam("startTime") String startTime,
                                           @QueryParam("endTime") String endTime,
                                           @QueryParam("page") Integer page,
                                           @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserService.searchByLastLoginTimeRange(startTime, endTime, resolvedPage, resolvedSize)).build();
    }

    @POST
    @Path("/{userId}/roles")
    @RunOnVirtualThread
    public Response addUserRole(@PathParam("userId") Long userId,
                                SysUserRole relation,
                                @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setUserId(userId);
            if (useKey) {
                if (sysUserRoleService.shouldSkipProcessing(idempotencyKey)) {
                    return Response.status(208).build();
                }
                sysUserRoleService.checkAndInsertIdempotency(idempotencyKey, relation, "create");
            }
            SysUserRole saved = sysUserRoleService.createRelation(relation);
            if (useKey && saved.getId() != null) {
                sysUserRoleService.markHistorySuccess(idempotencyKey, saved.getId());
            }
            return Response.status(Response.Status.CREATED).entity(saved).build();
        } catch (Exception ex) {
            if (useKey) {
                sysUserRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Add user role failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @DELETE
    @Path("/roles/{relationId}")
    @RunOnVirtualThread
    public Response deleteUserRole(@PathParam("relationId") Long relationId) {
        try {
            sysUserRoleService.deleteRelation(relationId);
            return Response.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete user role failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/{userId}/roles")
    @RunOnVirtualThread
    public Response listUserRoles(@PathParam("userId") Long userId,
                                  @QueryParam("page") Integer page,
                                  @QueryParam("size") Integer size) {
        try {
            int resolvedPage = page == null ? 1 : page;
            int resolvedSize = size == null ? 20 : size;
            return Response.ok(sysUserRoleService.findByUserId(userId, resolvedPage, resolvedSize)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List user roles failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @PUT
    @Path("/role-bindings/{relationId}")
    @RunOnVirtualThread
    public Response updateUserRole(@PathParam("relationId") Long relationId,
                                   SysUserRole relation,
                                   @HeaderParam("Idempotency-Key") String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setId(relationId);
            if (useKey) {
                sysUserRoleService.checkAndInsertIdempotency(idempotencyKey, relation, "update");
            }
            SysUserRole updated = sysUserRoleService.updateRelation(relation);
            if (useKey && updated.getId() != null) {
                sysUserRoleService.markHistorySuccess(idempotencyKey, updated.getId());
            }
            return Response.ok(updated).build();
        } catch (Exception ex) {
            if (useKey) {
                sysUserRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update user role failed", ex);
            return Response.status(resolveStatus(ex)).build();
        }
    }

    @GET
    @Path("/role-bindings/{relationId}")
    @RunOnVirtualThread
    public Response getUserRole(@PathParam("relationId") Long relationId) {
        SysUserRole relation = sysUserRoleService.findById(relationId);
        return relation == null ? Response.status(Response.Status.NOT_FOUND).build() : Response.ok(relation).build();
    }

    @GET
    @Path("/role-bindings")
    @RunOnVirtualThread
    public Response listRoleBindings(@QueryParam("page") Integer page,
                                     @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserRoleService.findAll(resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/role-bindings/by-role/{roleId}")
    @RunOnVirtualThread
    public Response listBindingsByRole(@PathParam("roleId") Integer roleId,
                                       @QueryParam("page") Integer page,
                                       @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserRoleService.findByRoleId(roleId, resolvedPage, resolvedSize)).build();
    }

    @GET
    @Path("/role-bindings/search")
    @RunOnVirtualThread
    public Response searchBindings(@QueryParam("userId") Long userId,
                                   @QueryParam("roleId") Integer roleId,
                                   @QueryParam("page") Integer page,
                                   @QueryParam("size") Integer size) {
        int resolvedPage = page == null ? 1 : page;
        int resolvedSize = size == null ? 20 : size;
        return Response.ok(sysUserRoleService.findByUserIdAndRoleId(userId, roleId, resolvedPage, resolvedSize)).build();
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
