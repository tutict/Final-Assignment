package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.dto.response.ApiResponse;

import com.tutict.finalassignmentbackend.dto.mapper.OffenseRecordRequestMapper;
import com.tutict.finalassignmentbackend.dto.request.OffenseCreateRequest;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.entity.OffenseRecord;
import com.tutict.finalassignmentbackend.service.AuthWsService;
import com.tutict.finalassignmentbackend.service.OffenseRecordService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
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
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/offenses")
@Tag(name = "Offense Management", description = "交通违法记录管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "APPEAL_REVIEWER"})
public class OffenseInformationController {

    private static final Logger LOG = Logger.getLogger(OffenseInformationController.class.getName());
    private static final Set<String> ELEVATED_AUTHORITIES = Set.of(
            "ROLE_SUPER_ADMIN",
            "ROLE_ADMIN",
            "ROLE_TRAFFIC_POLICE",
            "ROLE_APPEAL_REVIEWER"
    );

    private final AuthWsService authWsService;
    private final OffenseRecordService offenseRecordService;

    @Autowired
    public OffenseInformationController(AuthWsService authWsService,
                                        OffenseRecordService offenseRecordService) {
        this.authWsService = authWsService;
        this.offenseRecordService = offenseRecordService;
    }

    public OffenseInformationController(OffenseRecordService offenseRecordService) {
        this(null, offenseRecordService);
    }

    @PostMapping
    @Operation(summary = "创建违法记录")
    public ResponseEntity<?> create(@Valid @RequestBody OffenseCreateRequest request,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        OffenseRecord offenseRecord = OffenseRecordRequestMapper.toEntity(request);
        try {
            if (useKey) {
                if (offenseRecordService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).body(ApiResponse.ok(null));
                }
                offenseRecordService.checkAndInsertIdempotency(idempotencyKey, offenseRecord, "create");
            }
            OffenseRecord saved = offenseRecordService.createOffenseRecord(offenseRecord);
            if (useKey && saved.getOffenseId() != null) {
                offenseRecordService.markHistorySuccess(idempotencyKey, saved.getOffenseId());
                offenseRecordService.publishCreateKafkaAfterCommit(idempotencyKey, saved);
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (RuntimeException ex) {
            if (useKey) {
                offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create offense failed", ex);
            throw ex;
        }
    }

    @PutMapping("/{offenseId}")
    @Operation(summary = "更新违法记录")
    public ResponseEntity<OffenseRecord> update(@PathVariable Long offenseId,
                                                @Valid @RequestBody OffenseCreateRequest request,
                                                @RequestHeader(value = "Idempotency-Key", required = false)
                                                String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        OffenseRecord offenseRecord = OffenseRecordRequestMapper.toEntity(request);
        try {
            offenseRecord.setOffenseId(offenseId);
            if (useKey) {
                offenseRecordService.checkAndInsertIdempotency(idempotencyKey, offenseRecord, "update");
            }
            OffenseRecord updated = offenseRecordService.updateOffenseRecord(offenseRecord);
            if (useKey && updated.getOffenseId() != null) {
                offenseRecordService.markHistorySuccess(idempotencyKey, updated.getOffenseId());
            }
            return ResponseEntity.ok(updated);
        } catch (RuntimeException ex) {
            if (useKey) {
                offenseRecordService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update offense failed", ex);
            throw ex;
        }
    }

    @DeleteMapping("/{offenseId}")
    @Operation(summary = "删除违法记录")
    public ResponseEntity<Void> delete(@PathVariable Long offenseId) {
        try {
            offenseRecordService.deleteOffenseRecord(offenseId);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException ex) {
            LOG.log(Level.WARNING, "Delete offense failed", ex);
            throw ex;
        }
    }

    @GetMapping("/{offenseId}")
    @Operation(summary = "查询违法详情")
    public ResponseEntity<OffenseRecord> get(@PathVariable Long offenseId) {
        try {
            OffenseRecord record = offenseRecordService.findById(offenseId);
            return record == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(record);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get offense failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping
    @Operation(summary = "查询全部违法记录")
    public ResponseEntity<List<OffenseRecord>> list() {
        try {
            return ResponseEntity.ok(offenseRecordService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/driver/{driverId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "APPEAL_REVIEWER", "USER"})
    @Operation(summary = "按驾驶证分页查询违法")
    public ResponseEntity<List<OffenseRecord>> byDriver(@PathVariable Long driverId,
                                                        @RequestParam(defaultValue = "1") int page,
                                                        @RequestParam(defaultValue = "20") int size,
                                                        Authentication authentication) {
        try {
            if (!canAccessDriver(authentication, driverId)) {
                throw new org.springframework.security.access.AccessDeniedException("Forbidden");
            }
            return ResponseEntity.ok(offenseRecordService.findByDriverId(driverId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses by driver failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/vehicle/{vehicleId}")
    @Operation(summary = "按车辆分页查询违法")
    public ResponseEntity<List<OffenseRecord>> byVehicle(@PathVariable Long vehicleId,
                                                         @RequestParam(defaultValue = "1") int page,
                                                         @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.findByVehicleId(vehicleId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List offenses by vehicle failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/code")
    @Operation(summary = "按违法代码搜索")
    public ResponseEntity<List<OffenseRecord>> searchByCode(@RequestParam String offenseCode,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseCode(offenseCode, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by code failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/status")
    @Operation(summary = "按处理状态搜索")
    public ResponseEntity<List<OffenseRecord>> searchByStatus(@RequestParam String status,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByProcessStatus(status, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by status failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/time-range")
    @Operation(summary = "按违法时间范围搜索")
    public ResponseEntity<List<OffenseRecord>> searchByTimeRange(@RequestParam String startTime,
                                                                 @RequestParam String endTime,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseTimeRange(startTime, endTime, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by time range failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/number")
    @Operation(summary = "按违法编号搜索")
    public ResponseEntity<List<OffenseRecord>> searchByNumber(@RequestParam String offenseNumber,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseNumber(offenseNumber, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by number failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/location")
    @Operation(summary = "Search offenses by location")
    public ResponseEntity<List<OffenseRecord>> searchByLocation(@RequestParam String offenseLocation,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseLocation(offenseLocation, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by location failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/province")
    @Operation(summary = "Search offenses by province")
    public ResponseEntity<List<OffenseRecord>> searchByProvince(@RequestParam String offenseProvince,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseProvince(offenseProvince, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by province failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/city")
    @Operation(summary = "Search offenses by city")
    public ResponseEntity<List<OffenseRecord>> searchByCity(@RequestParam String offenseCity,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByOffenseCity(offenseCity, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by city failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/notification")
    @Operation(summary = "Search offenses by notification status")
    public ResponseEntity<List<OffenseRecord>> searchByNotification(@RequestParam String notificationStatus,
                                                                    @RequestParam(defaultValue = "1") int page,
                                                                    @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByNotificationStatus(notificationStatus, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by notification status failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/agency")
    @Operation(summary = "Search offenses by enforcement agency")
    public ResponseEntity<List<OffenseRecord>> searchByAgency(@RequestParam String enforcementAgency,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByEnforcementAgency(enforcementAgency, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by enforcement agency failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/fine-range")
    @Operation(summary = "Search offenses by fine amount range")
    public ResponseEntity<List<OffenseRecord>> searchByFineRange(@RequestParam double minAmount,
                                                                 @RequestParam double maxAmount,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(offenseRecordService.searchByFineAmountRange(minAmount, maxAmount, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search offense by fine amount range failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private boolean canAccessDriver(Authentication authentication, Long driverId) {
        if (authentication == null || driverId == null) {
            return false;
        }
        boolean elevated = authentication.getAuthorities().stream()
                .anyMatch(authority -> ELEVATED_AUTHORITIES.contains(authority.getAuthority()));
        if (elevated) {
            return true;
        }
        boolean regularUser = authentication.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_USER".equals(authority.getAuthority()));
        if (!regularUser) {
            return false;
        }
        if (authWsService == null) {
            return false;
        }
        UserProfileResponse profile = authWsService.getCurrentUserProfile(authentication.getName());
        return Objects.equals(profile.getDriverId(), driverId);
    }

    private HttpStatus resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? HttpStatus.BAD_REQUEST
                : HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
