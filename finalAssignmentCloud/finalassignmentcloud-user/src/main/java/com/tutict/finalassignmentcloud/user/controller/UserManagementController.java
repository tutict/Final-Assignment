package com.tutict.finalassignmentcloud.user.controller;

import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.entity.SysUserRole;
import com.tutict.finalassignmentcloud.user.service.SysUserRoleService;
import com.tutict.finalassignmentcloud.user.service.SysUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
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
@Tag(name = "User Management", description = "系统用户与角色管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class UserManagementController {

    private static final Logger LOG = Logger.getLogger(UserManagementController.class.getName());

    private final SysUserService sysUserService;
    private final SysUserRoleService sysUserRoleService;

    public UserManagementController(SysUserService sysUserService,
                                    SysUserRoleService sysUserRoleService) {
        this.sysUserService = sysUserService;
        this.sysUserRoleService = sysUserRoleService;
    }

    @PostMapping
    @Operation(summary = "创建用户")
    public ResponseEntity<SysUser> createUser(@RequestBody SysUser request,
                                              @RequestHeader(value = "Idempotency-Key", required = false)
                                              String idempotencyKey) {
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
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                sysUserService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create user failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{userId}")
    @Operation(summary = "更新用户")
    public ResponseEntity<SysUser> updateUser(@PathVariable Long userId,
                                              @RequestBody SysUser request,
                                              @RequestHeader(value = "Idempotency-Key", required = false)
                                              String idempotencyKey) {
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
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                sysUserService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update user failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{userId}")
    @Operation(summary = "删除用户")
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
    @Operation(summary = "查询用户详情")
    public ResponseEntity<SysUser> getUser(@PathVariable Long userId) {
        try {
            SysUser user = sysUserService.findById(userId);
            return user == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(user);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get user failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部用户")
    public ResponseEntity<List<SysUser>> listUsers() {
        try {
            return ResponseEntity.ok(sysUserService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/username/{username}")
    @Operation(summary = "按用户名查询用户")
    public ResponseEntity<SysUser> getByUsername(@PathVariable String username) {
        try {
            SysUser user = sysUserService.findByUsername(username);
            return user == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(user);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get user by username failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/username/prefix")
    @Operation(summary = "Search users by username prefix")
    public ResponseEntity<List<SysUser>> searchByUsernamePrefix(@RequestParam String username,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByUsernamePrefix(username, page, size));
    }

    @GetMapping("/search/username/fuzzy")
    @Operation(summary = "Search users by username fuzzy")
    public ResponseEntity<List<SysUser>> searchByUsernameFuzzy(@RequestParam String username,
                                                               @RequestParam(defaultValue = "1") int page,
                                                               @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByUsernameFuzzy(username, page, size));
    }

    @GetMapping("/search/real-name/prefix")
    @Operation(summary = "Search users by real name prefix")
    public ResponseEntity<List<SysUser>> searchByRealNamePrefix(@RequestParam String realName,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByRealNamePrefix(realName, page, size));
    }

    @GetMapping("/search/real-name/fuzzy")
    @Operation(summary = "Search users by real name fuzzy")
    public ResponseEntity<List<SysUser>> searchByRealNameFuzzy(@RequestParam String realName,
                                                               @RequestParam(defaultValue = "1") int page,
                                                               @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByRealNameFuzzy(realName, page, size));
    }

    @GetMapping("/search/id-card")
    @Operation(summary = "Search users by ID card number")
    public ResponseEntity<List<SysUser>> searchByIdCard(@RequestParam String idCardNumber,
                                                        @RequestParam(defaultValue = "1") int page,
                                                        @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByIdCardNumber(idCardNumber, page, size));
    }

    @GetMapping("/search/contact")
    @Operation(summary = "Search users by contact number")
    public ResponseEntity<List<SysUser>> searchByContact(@RequestParam String contactNumber,
                                                         @RequestParam(defaultValue = "1") int page,
                                                         @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByContactNumber(contactNumber, page, size));
    }

    @GetMapping("/search/status")
    @Operation(summary = "按状态分页查询用户")
    public ResponseEntity<List<SysUser>> listByStatus(@RequestParam String status,
                                                      @RequestParam(defaultValue = "1") int page,
                                                      @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(sysUserService.findByStatus(status, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users by status failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/department")
    @Operation(summary = "按部门分页查询用户")
    public ResponseEntity<List<SysUser>> listByDepartment(@RequestParam String department,
                                                          @RequestParam(defaultValue = "1") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(sysUserService.findByDepartment(department, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users by department failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/department/prefix")
    @Operation(summary = "Search users by department prefix")
    public ResponseEntity<List<SysUser>> searchByDepartmentPrefix(@RequestParam String department,
                                                                  @RequestParam(defaultValue = "1") int page,
                                                                  @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByDepartmentPrefix(department, page, size));
    }

    @GetMapping("/search/employee-number")
    @Operation(summary = "Search users by employee number")
    public ResponseEntity<List<SysUser>> searchByEmployeeNumber(@RequestParam String employeeNumber,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByEmployeeNumber(employeeNumber, page, size));
    }

    @GetMapping("/search/last-login-range")
    @Operation(summary = "Search users by last login time range")
    public ResponseEntity<List<SysUser>> searchByLastLoginRange(@RequestParam String startTime,
                                                                @RequestParam String endTime,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserService.searchByLastLoginTimeRange(startTime, endTime, page, size));
    }

    @PostMapping("/{userId}/roles")
    @Operation(summary = "绑定用户角色")
    public ResponseEntity<SysUserRole> addUserRole(@PathVariable Long userId,
                                                   @RequestBody SysUserRole relation,
                                                   @RequestHeader(value = "Idempotency-Key", required = false)
                                                   String idempotencyKey) {
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
    @Operation(summary = "删除用户角色关联")
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
    @Operation(summary = "查询用户角色列表")
    public ResponseEntity<List<SysUserRole>> listUserRoles(@PathVariable Long userId,
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
    @Operation(summary = "更新用户角色关联")
    public ResponseEntity<SysUserRole> updateUserRole(@PathVariable Long relationId,
                                                      @RequestBody SysUserRole relation,
                                                      @RequestHeader(value = "Idempotency-Key", required = false)
                                                      String idempotencyKey) {
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
    @Operation(summary = "查询用户角色关联详情")
    public ResponseEntity<SysUserRole> getUserRole(@PathVariable Long relationId) {
        SysUserRole relation = sysUserRoleService.findById(relationId);
        return relation == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(relation);
    }

    @GetMapping("/role-bindings")
    @Operation(summary = "分页查询全部用户角色关联")
    public ResponseEntity<List<SysUserRole>> listRoleBindings(@RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserRoleService.findAll(page, size));
    }

    @GetMapping("/role-bindings/by-role/{roleId}")
    @Operation(summary = "按角色查询用户角色关联")
    public ResponseEntity<List<SysUserRole>> listBindingsByRole(@PathVariable Integer roleId,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserRoleService.findByRoleId(roleId, page, size));
    }

    @GetMapping("/role-bindings/search")
    @Operation(summary = "Search user role bindings by userId and roleId")
    public ResponseEntity<List<SysUserRole>> searchBindings(@RequestParam Long userId,
                                                            @RequestParam Integer roleId,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sysUserRoleService.findByUserIdAndRoleId(userId, roleId, page, size));
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
