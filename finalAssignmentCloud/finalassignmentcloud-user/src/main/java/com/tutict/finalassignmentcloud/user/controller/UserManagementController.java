package com.tutict.finalassignmentcloud.user.controller;

import com.tutict.finalassignmentcloud.dto.response.SysUserResponse;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.entity.SysUserRole;
import com.tutict.finalassignmentcloud.user.service.SysUserRoleService;
import com.tutict.finalassignmentcloud.user.service.SysUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/users")
@Tag(name = "User Management", description = "System user and role management APIs")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class UserManagementController {

    private static final Logger LOG = Logger.getLogger(UserManagementController.class.getName());

    private final SysUserService sysUserService;
    private final SysUserRoleService sysUserRoleService;
    private final String internalServiceToken;

    public UserManagementController(SysUserService sysUserService,
                                    SysUserRoleService sysUserRoleService,
                                    @Value("${cloud.internal.service-token:${CLOUD_INTERNAL_SERVICE_TOKEN:}}")
                                    String internalServiceToken) {
        this.sysUserService = sysUserService;
        this.sysUserRoleService = sysUserRoleService;
        this.internalServiceToken = internalServiceToken;
    }

    @PostMapping
    @Operation(summary = "Create user")
    public ResponseEntity<SysUserResponse> createUser(
            @RequestBody SysUser request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (sysUserService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                sysUserService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            SysUser saved = sysUserService.createSysUser(request);
            if (useKey && saved.getUserId() != null) {
                sysUserService.markHistorySuccess(idempotencyKey, saved.getUserId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
        } catch (Exception ex) {
            if (useKey) {
                sysUserService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create user failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{userId}")
    @Operation(summary = "Update user")
    public ResponseEntity<SysUserResponse> updateUser(
            @PathVariable Long userId,
            @RequestBody SysUser request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
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
            return ResponseEntity.ok(toResponse(updated));
        } catch (Exception ex) {
            if (useKey) {
                sysUserService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update user failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{userId}")
    @Operation(summary = "Delete user")
    public ResponseEntity<Void> deleteUser(@PathVariable Long userId) {
        try {
            sysUserService.deleteSysUser(userId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete user failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{userId}")
    @Operation(summary = "Get user")
    public ResponseEntity<SysUserResponse> getUser(@PathVariable Long userId) {
        try {
            SysUser user = sysUserService.findById(userId);
            return user == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(toResponse(user));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get user failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "List users")
    public ResponseEntity<List<SysUserResponse>> listUsers() {
        try {
            return ResponseEntity.ok(toResponses(sysUserService.findAll()));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/username/{username}")
    @Operation(summary = "Get user by username")
    public ResponseEntity<SysUserResponse> getByUsername(@PathVariable String username) {
        try {
            SysUser user = sysUserService.findByUsername(username);
            return user == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(toResponse(user));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get user by username failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/internal/search/username/{username}")
    @PermitAll
    @Operation(summary = "Internal credential lookup")
    public ResponseEntity<SysUser> getInternalByUsername(
            @PathVariable String username,
            @RequestHeader(value = "X-Internal-Service-Token", required = false) String serviceToken) {
        if (!isValidInternalToken(serviceToken)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        try {
            SysUser user = sysUserService.findByUsername(username);
            return user == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(user);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Internal user lookup failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/username/prefix")
    @Operation(summary = "Search users by username prefix")
    public ResponseEntity<List<SysUserResponse>> searchByUsernamePrefix(
            @RequestParam String username,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByUsernamePrefix(username, page, size)));
    }

    @GetMapping("/search/username/fuzzy")
    @Operation(summary = "Search users by username fuzzy")
    public ResponseEntity<List<SysUserResponse>> searchByUsernameFuzzy(
            @RequestParam String username,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByUsernameFuzzy(username, page, size)));
    }

    @GetMapping("/autocomplete/usernames")
    @Operation(summary = "Autocomplete usernames")
    public ResponseEntity<List<String>> autocompleteUsernames(
            @RequestParam String prefix,
            @RequestParam(defaultValue = "10") int size) {
        try {
            return ResponseEntity.ok(sysUserService.getUsernameAutocompleteSuggestions(prefix, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Autocomplete usernames failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/real-name/prefix")
    @Operation(summary = "Search users by real name prefix")
    public ResponseEntity<List<SysUserResponse>> searchByRealNamePrefix(
            @RequestParam String realName,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByRealNamePrefix(realName, page, size)));
    }

    @GetMapping("/search/real-name/fuzzy")
    @Operation(summary = "Search users by real name fuzzy")
    public ResponseEntity<List<SysUserResponse>> searchByRealNameFuzzy(
            @RequestParam String realName,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByRealNameFuzzy(realName, page, size)));
    }

    @GetMapping("/search/id-card")
    @Operation(summary = "Search users by ID card number")
    public ResponseEntity<List<SysUserResponse>> searchByIdCard(
            @RequestParam String idCardNumber,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByIdCardNumber(idCardNumber, page, size)));
    }

    @GetMapping("/search/contact")
    @Operation(summary = "Search users by contact number")
    public ResponseEntity<List<SysUserResponse>> searchByContact(
            @RequestParam String contactNumber,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByContactNumber(contactNumber, page, size)));
    }

    @GetMapping("/search/status")
    @Operation(summary = "List users by status")
    public ResponseEntity<List<SysUserResponse>> listByStatus(
            @RequestParam String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(toResponses(sysUserService.findByStatus(status, page, size)));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users by status failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/department")
    @Operation(summary = "List users by department")
    public ResponseEntity<List<SysUserResponse>> listByDepartment(
            @RequestParam String department,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(toResponses(sysUserService.findByDepartment(department, page, size)));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users by department failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/department/prefix")
    @Operation(summary = "Search users by department prefix")
    public ResponseEntity<List<SysUserResponse>> searchByDepartmentPrefix(
            @RequestParam String department,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByDepartmentPrefix(department, page, size)));
    }

    @GetMapping("/search/employee-number")
    @Operation(summary = "Search users by employee number")
    public ResponseEntity<List<SysUserResponse>> searchByEmployeeNumber(
            @RequestParam String employeeNumber,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByEmployeeNumber(employeeNumber, page, size)));
    }

    @GetMapping("/search/last-login-range")
    @Operation(summary = "Search users by last login time range")
    public ResponseEntity<List<SysUserResponse>> searchByLastLoginRange(
            @RequestParam String startTime,
            @RequestParam String endTime,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(toResponses(sysUserService.searchByLastLoginTimeRange(startTime, endTime, page, size)));
    }

    @PostMapping("/{userId}/roles")
    @Operation(summary = "Add user role")
    public ResponseEntity<SysUserRole> addUserRole(
            @PathVariable Long userId,
            @RequestBody SysUserRole relation,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setUserId(userId);
            if (useKey) {
                if (sysUserRoleService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                sysUserRoleService.checkAndInsertIdempotency(idempotencyKey, relation, "create");
            }
            SysUserRole saved = sysUserRoleService.createRelation(relation);
            if (useKey && saved.getId() != null) {
                sysUserRoleService.markHistorySuccess(idempotencyKey, saved.getId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                sysUserRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Add user role failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/roles/{relationId}")
    @Operation(summary = "Delete user role relation")
    public ResponseEntity<Void> deleteUserRole(@PathVariable Long relationId) {
        try {
            sysUserRoleService.deleteRelation(relationId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete user role failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{userId}/roles")
    @Operation(summary = "List user roles")
    public ResponseEntity<List<SysUserRole>> listUserRoles(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(sysUserRoleService.findByUserId(userId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List user roles failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/role-bindings/{relationId}")
    @Operation(summary = "Update user role relation")
    public ResponseEntity<SysUserRole> updateUserRole(
            @PathVariable Long relationId,
            @RequestBody SysUserRole relation,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
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
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                sysUserRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update user role failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/role-bindings/{relationId}")
    @Operation(summary = "Get user role relation")
    public ResponseEntity<SysUserRole> getUserRole(@PathVariable Long relationId) {
        SysUserRole relation = sysUserRoleService.findById(relationId);
        return relation == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(relation);
    }

    @GetMapping("/role-bindings")
    @Operation(summary = "List role bindings")
    public ResponseEntity<List<SysUserRole>> listRoleBindings(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserRoleService.findAll(page, size));
    }

    @GetMapping("/role-bindings/by-role/{roleId}")
    @Operation(summary = "List role bindings by role")
    public ResponseEntity<List<SysUserRole>> listBindingsByRole(
            @PathVariable Integer roleId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserRoleService.findByRoleId(roleId, page, size));
    }

    @GetMapping("/role-bindings/search")
    @Operation(summary = "Search role bindings")
    public ResponseEntity<List<SysUserRole>> searchBindings(
            @RequestParam Long userId,
            @RequestParam Integer roleId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserRoleService.findByUserIdAndRoleId(userId, roleId, page, size));
    }

    private SysUserResponse toResponse(SysUser user) {
        return SysUserResponse.fromEntity(user);
    }

    private List<SysUserResponse> toResponses(List<SysUser> users) {
        if (users == null || users.isEmpty()) {
            return List.of();
        }
        return users.stream()
                .map(this::toResponse)
                .toList();
    }

    private boolean isValidInternalToken(String serviceToken) {
        return hasKey(internalServiceToken) && internalServiceToken.equals(serviceToken);
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private HttpStatus resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? HttpStatus.BAD_REQUEST
                : HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
