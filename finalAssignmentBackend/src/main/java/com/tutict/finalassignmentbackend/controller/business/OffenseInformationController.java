package com.tutict.finalassignmentbackend.controller.business;

import com.tutict.finalassignmentbackend.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;

import com.tutict.finalassignmentbackend.dto.mapper.OffenseRecordRequestMapper;
import com.tutict.finalassignmentbackend.dto.request.OffenseCreateRequest;
import com.tutict.finalassignmentbackend.dto.response.OffenseDetailResponse;
import com.tutict.finalassignmentbackend.dto.response.PageResponse;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.service.auth.AuthWsService;
import com.tutict.finalassignmentbackend.service.business.BusinessRecordViewService;
import com.tutict.finalassignmentbackend.service.offense.OffenseDetailService;
import com.tutict.finalassignmentbackend.service.offense.OffenseRecordService;
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
    private static final Set<String> ELEVATED_ROLES = Set.of(
            "SUPER_ADMIN",
            "ADMIN",
            "TRAFFIC_POLICE",
            "APPEAL_REVIEWER"
    );

    private final AuthWsService authWsService;
    private final OffenseRecordService offenseRecordService;
    private final OffenseDetailService offenseDetailService;
    private final BusinessRecordViewService businessRecordViewService;

    @Autowired
    public OffenseInformationController(AuthWsService authWsService,
                                        OffenseRecordService offenseRecordService,
                                        OffenseDetailService offenseDetailService,
                                        BusinessRecordViewService businessRecordViewService) {
        this.authWsService = authWsService;
        this.offenseRecordService = offenseRecordService;
        this.offenseDetailService = offenseDetailService;
        this.businessRecordViewService = businessRecordViewService;
    }

    public OffenseInformationController(OffenseRecordService offenseRecordService) {
        this(null, offenseRecordService, null, null);
    }

    @PostMapping
    @Operation(summary = "创建违法记录")
    public ResponseEntity<ApiResponse<OffenseRecord>> create(@Valid @RequestBody OffenseCreateRequest request,
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
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(saved));
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
    public ResponseEntity<ApiResponse<OffenseRecord>> update(@PathVariable Long offenseId,
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
            return ResponseEntity.ok(ApiResponse.ok(updated));
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
    public ResponseEntity<ApiResponse<OffenseRecord>> get(@PathVariable Long offenseId) {
        try {
            OffenseRecord record = offenseRecordService.findById(offenseId);
            if (record == null) {
                throw new com.tutict.finalassignmentbackend.exception.EntityNotFoundException("Offense not found: " + offenseId);
            }
            return ResponseEntity.ok(ApiResponse.ok(enrich(record)));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get offense failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/{offenseId}/details")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN"})
    @Operation(summary = "Get offense details")
    public ResponseEntity<ApiResponse<OffenseDetailResponse>> getDetails(@PathVariable Long offenseId) {
        return ResponseEntity.ok(ApiResponse.ok(offenseDetailService.getOffenseDetail(offenseId)));
    }

    @GetMapping
    @Operation(summary = "查询全部违法记录")
    public ResponseEntity<ApiResponse<PageResponse<OffenseRecord>>> list(@RequestParam(defaultValue = "0") int page,
                                                                         @RequestParam(defaultValue = "20") int size) {
        try {
            List<OffenseRecord> records = offenseRecordService.findAll();
            int normalizedPage = Math.max(page, 0);
            int normalizedSize = Math.max(size, 1);
            int from = Math.min(normalizedPage * normalizedSize, records.size());
            int to = Math.min(from + normalizedSize, records.size());
            return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(
                    enrich(records.subList(from, to)), records.size(), normalizedPage, normalizedSize)));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> byDriver(@PathVariable Long driverId,
                                                        @RequestParam(defaultValue = "1") int page,
                                                        @RequestParam(defaultValue = "20") int size,
                                                        Authentication authentication) {
        try {
            if (!canAccessDriver(authentication, driverId)) {
                throw new org.springframework.security.access.AccessDeniedException("Forbidden");
            }
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.findByDriverId(driverId, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> byVehicle(@PathVariable Long vehicleId,
                                                         @RequestParam(defaultValue = "1") int page,
                                                         @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.findByVehicleId(vehicleId, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByCode(@RequestParam String offenseCode,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByOffenseCode(offenseCode, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByStatus(@RequestParam String status,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByProcessStatus(status, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByTimeRange(@RequestParam String startTime,
                                                                 @RequestParam String endTime,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByOffenseTimeRange(startTime, endTime, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByNumber(@RequestParam String offenseNumber,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByOffenseNumber(offenseNumber, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByLocation(@RequestParam String offenseLocation,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByOffenseLocation(offenseLocation, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByProvince(@RequestParam String offenseProvince,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByOffenseProvince(offenseProvince, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByCity(@RequestParam String offenseCity,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByOffenseCity(offenseCity, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByNotification(@RequestParam String notificationStatus,
                                                                    @RequestParam(defaultValue = "1") int page,
                                                                    @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByNotificationStatus(notificationStatus, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByAgency(@RequestParam String enforcementAgency,
                                                              @RequestParam(defaultValue = "1") int page,
                                                              @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByEnforcementAgency(enforcementAgency, page, size))));
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
    public ResponseEntity<ApiResponse<List<OffenseRecord>>> searchByFineRange(@RequestParam double minAmount,
                                                                 @RequestParam double maxAmount,
                                                                 @RequestParam(defaultValue = "1") int page,
                                                                 @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(enrich(offenseRecordService.searchByFineAmountRange(minAmount, maxAmount, page, size))));
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

    private OffenseRecord enrich(OffenseRecord record) {
        return businessRecordViewService == null ? record : businessRecordViewService.enrichOffense(record);
    }

    private List<OffenseRecord> enrich(List<OffenseRecord> records) {
        return businessRecordViewService == null ? records : businessRecordViewService.enrichOffenses(records);
    }

    private boolean canAccessDriver(Authentication authentication, Long driverId) {
        if (authentication == null || driverId == null) {
            return false;
        }
        boolean elevated = SecurityRoleUtils.hasAnyRole(authentication, ELEVATED_ROLES);
        if (elevated) {
            return true;
        }
        boolean regularUser = SecurityRoleUtils.hasRole(authentication, "USER");
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
