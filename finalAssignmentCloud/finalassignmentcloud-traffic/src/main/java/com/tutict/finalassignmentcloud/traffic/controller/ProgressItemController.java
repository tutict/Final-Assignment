package com.tutict.finalassignmentcloud.traffic.controller;

import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.traffic.client.SystemRequestHistoryClient;
import feign.FeignException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.jdbc.core.JdbcTemplate;
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
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/progress")
@Tag(name = "Progress Tracker", description = "幂等请求进度跟踪接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN"})
public class ProgressItemController {

    private static final Logger LOG = Logger.getLogger(ProgressItemController.class.getName());

    private static boolean isRegularUser(Authentication authentication) {
        if (authentication == null) {
            return false;
        }
        boolean user = false;
        boolean staff = false;
        for (GrantedAuthority authority : authentication.getAuthorities()) {
            String role = authority.getAuthority();
            if (role == null) {
                continue;
            }
            if (role.contains("USER")) {
                user = true;
            }
            if (role.contains("ADMIN") || role.contains("STAFF")) {
                staff = true;
            }
        }
        return user && !staff;
    }

    private final SystemRequestHistoryClient requestHistoryClient;
    private final JdbcTemplate jdbcTemplate;

    public ProgressItemController(SystemRequestHistoryClient requestHistoryClient, JdbcTemplate jdbcTemplate) {
        this.requestHistoryClient = requestHistoryClient;
        this.jdbcTemplate = jdbcTemplate;
    }

    @PostMapping
    @Operation(summary = "创建进度记录")
    public ResponseEntity<SysRequestHistory> create(@RequestBody SysRequestHistory request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        try {
            SysRequestHistory saved = requestHistoryClient.create(request, idempotencyKey);
            if (saved == null) {
                return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Create request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PutMapping("/{historyId}")
    @Operation(summary = "更新进度记录")
    public ResponseEntity<SysRequestHistory> update(@PathVariable Long historyId,
                                                    @RequestBody SysRequestHistory request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        try {
            SysRequestHistory updated = requestHistoryClient.update(historyId, request, idempotencyKey);
            if (updated == null) {
                return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
            }
            return ResponseEntity.ok(updated);
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Update request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/{historyId}")
    @Operation(summary = "删除进度记录")
    public ResponseEntity<Void> delete(@PathVariable Long historyId) {
        try {
            requestHistoryClient.delete(historyId);
            return ResponseEntity.noContent().build();
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{historyId}")
    @Operation(summary = "查询进度记录")
    public ResponseEntity<SysRequestHistory> get(@PathVariable Long historyId) {
        try {
            SysRequestHistory history = requestHistoryClient.get(historyId);
            return history == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(history);
        } catch (FeignException.NotFound ex) {
            return ResponseEntity.notFound().build();
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get request history failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "USER"})
    @Operation(summary = "查询进度记录")
    public ResponseEntity<List<SysRequestHistory>> list(Authentication authentication) {
        try {
            if (isRegularUser(authentication)) {
                return ResponseEntity.ok(jdbcTemplate.query("""
                        SELECT h.id, h.idempotency_key, h.request_method, h.request_url, h.request_params,
                               h.business_type, h.business_id, h.business_status, h.user_id, h.request_ip,
                               h.created_at, h.updated_at
                        FROM sys_request_history h
                        JOIN sys_user u ON u.user_id = h.user_id
                        WHERE u.username = ? AND h.deleted_at IS NULL
                        ORDER BY h.updated_at DESC
                        LIMIT 50
                        """, (rs, row) -> {
                    SysRequestHistory history = new SysRequestHistory();
                    history.setId(rs.getLong("id"));
                    history.setIdempotencyKey(rs.getString("idempotency_key"));
                    history.setRequestMethod(rs.getString("request_method"));
                    history.setRequestUrl(rs.getString("request_url"));
                    history.setRequestParams(rs.getString("request_params"));
                    history.setBusinessType(rs.getString("business_type"));
                    history.setBusinessId(rs.getObject("business_id") == null ? null : rs.getLong("business_id"));
                    history.setBusinessStatus(rs.getString("business_status"));
                    history.setUserId(rs.getObject("user_id") == null ? null : rs.getLong("user_id"));
                    history.setRequestIp(rs.getString("request_ip"));
                    if (rs.getTimestamp("created_at") != null) {
                        history.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
                    }
                    if (rs.getTimestamp("updated_at") != null) {
                        history.setUpdatedAt(rs.getTimestamp("updated_at").toLocalDateTime());
                    }
                    return history;
                }, authentication.getName()));
            }
            return ResponseEntity.ok(requestHistoryClient.list());
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List request histories failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/status")
    @Operation(summary = "按业务状态分页查询进度记录")
    public ResponseEntity<List<SysRequestHistory>> listByStatus(@RequestParam String status,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(requestHistoryClient.listByStatus(status, page, size));
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/idempotency/{key}")
    @Operation(summary = "根据幂等键查询进度记录")
    public ResponseEntity<SysRequestHistory> getByIdempotencyKey(@PathVariable String key) {
        try {
            SysRequestHistory history = requestHistoryClient.getByIdempotencyKey(key);
            return history == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(history);
        } catch (FeignException.NotFound ex) {
            return ResponseEntity.notFound().build();
        } catch (FeignException ex) {
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    private HttpStatus resolveStatus(FeignException ex) {
        int status = ex.status();
        if (status == 400) {
            return HttpStatus.BAD_REQUEST;
        }
        if (status == 404) {
            return HttpStatus.NOT_FOUND;
        }
        if (status == 409) {
            return HttpStatus.CONFLICT;
        }
        if (status == 422) {
            return HttpStatus.UNPROCESSABLE_ENTITY;
        }
        return HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
