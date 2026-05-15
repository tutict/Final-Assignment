package com.tutict.finalassignmentbackend.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.common.PageRequest;
import com.tutict.finalassignmentbackend.dto.mapper.UserResponseMapper;
import com.tutict.finalassignmentbackend.dto.request.UserCreateRequest;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.dto.response.PageResponse;
import com.tutict.finalassignmentbackend.dto.response.UserResponse;
import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.entity.SysUserRole;
import com.tutict.finalassignmentbackend.service.SysUserRoleService;
import com.tutict.finalassignmentbackend.service.SysUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
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
    public ResponseEntity<ApiResponse<UserResponse>> createUser(@Valid @RequestBody UserCreateRequest request,
                                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            SysUser user = UserResponseMapper.toEntity(request);
            if (useKey) {
                if (sysUserService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED)
                            .body(ApiResponse.ok(null));
                }
                sysUserService.checkAndInsertIdempotency(idempotencyKey, user, "create");
            }
            SysUser saved = sysUserService.createSysUser(user);
            if (useKey && saved.getUserId() != null) {
                sysUserService.markHistorySuccess(idempotencyKey, saved.getUserId());
            }
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.ok(toUserResponse(saved)));
        } catch (RuntimeException ex) {
            if (useKey) {
                sysUserService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create user failed", ex);
            throw ex;
        }
    }

    @PutMapping("/{userId}")
    @Operation(summary = "更新用户")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(@PathVariable Long userId,
                                                                @Valid @RequestBody UserCreateRequest request,
                                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            SysUser user = UserResponseMapper.toEntity(request);
            user.setUserId(userId);
            if (useKey) {
                sysUserService.checkAndInsertIdempotency(idempotencyKey, user, "update");
            }
            SysUser updated = sysUserService.updateSysUser(user);
            if (useKey && updated.getUserId() != null) {
                sysUserService.markHistorySuccess(idempotencyKey, updated.getUserId());
            }
            return ResponseEntity.ok(ApiResponse.ok(toUserResponse(updated)));
        } catch (RuntimeException ex) {
            if (useKey) {
                sysUserService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update user failed", ex);
            throw ex;
        }
    }

    @DeleteMapping("/{userId}")
    @Operation(summary = "删除用户")
    public ResponseEntity<Void> deleteUser(@PathVariable Long userId) {
        try {
            sysUserService.deleteSysUser(userId);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException ex) {
            LOG.log(Level.WARNING, "Delete user failed", ex);
            throw ex;
        }
    }

    @GetMapping("/{userId}")
    @Operation(summary = "查询用户详情")
    public ResponseEntity<ApiResponse<UserResponse>> getUser(@PathVariable Long userId) {
        try {
            SysUser user = sysUserService.findById(userId);
            return user == null
                    ? ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("USER_NOT_FOUND", "User not found"))
                    : ResponseEntity.ok(ApiResponse.ok(toUserResponse(user)));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get user failed", ex);
            return ResponseEntity.status(resolveStatus(ex))
                    .body(ApiResponse.error("USER_QUERY_FAILED", ex.getMessage()));
        }
    }

    @GetMapping
    @Operation(summary = "查询全部用户")
    public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> listUsers(@Valid PageRequest pageRequest) {
        try {
            Page<SysUser> page = sysUserService.findPage(pageRequest);
            PageResponse<UserResponse> response = PageResponse.of(
                    toUserResponses(page.getRecords()),
                    page.getTotal(),
                    pageRequest.getPage(),
                    pageRequest.getSize());
            return ResponseEntity.ok(ApiResponse.ok(response));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users failed", ex);
            return ResponseEntity.status(resolveStatus(ex))
                    .body(ApiResponse.error("USER_LIST_FAILED", ex.getMessage()));
        }
    }

    @GetMapping("/search/username/{username}")
    @Operation(summary = "按用户名查询用户")
    public ResponseEntity<ApiResponse<UserResponse>> getByUsername(@PathVariable String username) {
        try {
            SysUser user = sysUserService.findByUsername(username);
            return user == null
                    ? ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("USER_NOT_FOUND", "User not found"))
                    : ResponseEntity.ok(ApiResponse.ok(toUserResponse(user)));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get user by username failed", ex);
            return ResponseEntity.status(resolveStatus(ex))
                    .body(ApiResponse.error("USER_QUERY_FAILED", ex.getMessage()));
        }
    }

    @GetMapping("/search/username/prefix")
    @Operation(summary = "Search users by username prefix")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByUsernamePrefix(@RequestParam String username,
                                                                                  @RequestParam(defaultValue = "1") int page,
                                                                                  @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByUsernamePrefix(username, page, size))));
    }

    @GetMapping("/search/username/fuzzy")
    @Operation(summary = "Search users by username fuzzy")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByUsernameFuzzy(@RequestParam String username,
                                                                                 @RequestParam(defaultValue = "1") int page,
                                                                                 @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByUsernameFuzzy(username, page, size))));
    }

    @GetMapping("/search/real-name/prefix")
    @Operation(summary = "Search users by real name prefix")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByRealNamePrefix(@RequestParam String realName,
                                                                                  @RequestParam(defaultValue = "1") int page,
                                                                                  @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByRealNamePrefix(realName, page, size))));
    }

    @GetMapping("/search/real-name/fuzzy")
    @Operation(summary = "Search users by real name fuzzy")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByRealNameFuzzy(@RequestParam String realName,
                                                                                 @RequestParam(defaultValue = "1") int page,
                                                                                 @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByRealNameFuzzy(realName, page, size))));
    }

    @GetMapping("/search/id-card")
    @Operation(summary = "Search users by ID card number")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByIdCard(@RequestParam String idCardNumber,
                                                                          @RequestParam(defaultValue = "1") int page,
                                                                          @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByIdCardNumber(idCardNumber, page, size))));
    }

    @GetMapping("/search/contact")
    @Operation(summary = "Search users by contact number")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByContact(@RequestParam String contactNumber,
                                                                           @RequestParam(defaultValue = "1") int page,
                                                                           @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByContactNumber(contactNumber, page, size))));
    }

    @GetMapping("/search/status")
    @Operation(summary = "按状态分页查询用户")
    public ResponseEntity<ApiResponse<List<UserResponse>>> listByStatus(@RequestParam String status,
                                                                        @RequestParam(defaultValue = "1") int page,
                                                                        @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.findByStatus(status, page, size))));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users by status failed", ex);
            return ResponseEntity.status(resolveStatus(ex))
                    .body(ApiResponse.error("USER_LIST_FAILED", ex.getMessage()));
        }
    }

    @GetMapping("/search/department")
    @Operation(summary = "按部门分页查询用户")
    public ResponseEntity<ApiResponse<List<UserResponse>>> listByDepartment(@RequestParam String department,
                                                                            @RequestParam(defaultValue = "1") int page,
                                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.findByDepartment(department, page, size))));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List users by department failed", ex);
            return ResponseEntity.status(resolveStatus(ex))
                    .body(ApiResponse.error("USER_LIST_FAILED", ex.getMessage()));
        }
    }

    @GetMapping("/search/department/prefix")
    @Operation(summary = "Search users by department prefix")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByDepartmentPrefix(@RequestParam String department,
                                                                                    @RequestParam(defaultValue = "1") int page,
                                                                                    @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByDepartmentPrefix(department, page, size))));
    }

    @GetMapping("/search/employee-number")
    @Operation(summary = "Search users by employee number")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByEmployeeNumber(@RequestParam String employeeNumber,
                                                                                  @RequestParam(defaultValue = "1") int page,
                                                                                  @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByEmployeeNumber(employeeNumber, page, size))));
    }

    @GetMapping("/search/last-login-range")
    @Operation(summary = "Search users by last login time range")
    public ResponseEntity<ApiResponse<List<UserResponse>>> searchByLastLoginRange(@RequestParam String startTime,
                                                                                  @RequestParam String endTime,
                                                                                  @RequestParam(defaultValue = "1") int page,
                                                                                  @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(toUserResponses(sysUserService.searchByLastLoginTimeRange(startTime, endTime, page, size))));
    }

    @PostMapping("/{userId}/roles")
    @Operation(summary = "绑定用户角色")
    public ResponseEntity<?> addUserRole(@PathVariable Long userId,
                                                   @Valid @RequestBody SysUserRole relation,
                                                   @RequestHeader(value = "Idempotency-Key", required = false)
                                                   String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setUserId(userId);
            if (useKey) {
                if (sysUserRoleService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).body(ApiResponse.ok(null));
                }
                sysUserRoleService.checkAndInsertIdempotency(idempotencyKey, relation, "create");
            }
            SysUserRole saved = sysUserRoleService.createRelation(relation);
            if (useKey && saved.getId() != null) {
                sysUserRoleService.markHistorySuccess(idempotencyKey, saved.getId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (RuntimeException ex) {
            if (useKey) {
                sysUserRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Add user role failed", ex);
            throw ex;
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
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
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
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @PutMapping("/role-bindings/{relationId}")
    @Operation(summary = "更新用户角色关联")
    public ResponseEntity<SysUserRole> updateUserRole(@PathVariable Long relationId,
                                                      @Valid @RequestBody SysUserRole relation,
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
        } catch (RuntimeException ex) {
            if (useKey) {
                sysUserRoleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update user role failed", ex);
            throw ex;
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

    private UserResponse toUserResponse(SysUser user) {
        return UserResponseMapper.toResponse(user);
    }

    private List<UserResponse> toUserResponses(List<SysUser> users) {
        if (users == null || users.isEmpty()) {
            return List.of();
        }
        return users.stream()
                .map(this::toUserResponse)
                .toList();
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
