package com.tutict.finalassignmentbackend.controller.business;

import com.tutict.finalassignmentbackend.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;

import com.tutict.finalassignmentbackend.dto.request.DriverCreateRequest;
import com.tutict.finalassignmentbackend.dto.response.DriverResponse;
import com.tutict.finalassignmentbackend.dto.response.PageResponse;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.entity.driver.DriverInformation;
import com.tutict.finalassignmentbackend.service.auth.AuthWsService;
import com.tutict.finalassignmentbackend.service.driver.DriverInformationService;
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
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/drivers")
@Tag(name = "Driver Information", description = "驾驶员档案管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class DriverInformationController {

    private static final Logger LOG = Logger.getLogger(DriverInformationController.class.getName());
    private static final Set<String> ELEVATED_ROLES = Set.of(
            "SUPER_ADMIN",
            "ADMIN",
            "TRAFFIC_POLICE"
    );

    private final AuthWsService authWsService;
    private final DriverInformationService driverInformationService;

    @Autowired
    public DriverInformationController(AuthWsService authWsService,
                                       DriverInformationService driverInformationService) {
        this.authWsService = authWsService;
        this.driverInformationService = driverInformationService;
    }

    public DriverInformationController(DriverInformationService driverInformationService) {
        this(null, driverInformationService);
    }

    @PostMapping
    @Operation(summary = "创建驾驶员档案")
    public ResponseEntity<ApiResponse<DriverResponse>> create(@Valid @RequestBody DriverCreateRequest request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        DriverInformation driver = request.toEntity();
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (driverInformationService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).body(ApiResponse.ok(null));
                }
                driverInformationService.checkAndInsertIdempotency(idempotencyKey, driver, "create");
            }
            DriverInformation saved = driverInformationService.createDriver(driver);
            if (useKey && saved.getDriverId() != null) {
                driverInformationService.markHistorySuccess(idempotencyKey, saved.getDriverId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(DriverResponse.from(saved)));
        } catch (Exception ex) {
            if (useKey) {
                driverInformationService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create driver failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @PutMapping("/{driverId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @Operation(summary = "更新驾驶员档案")
    public ResponseEntity<DriverInformation> update(@PathVariable Long driverId,
                                                    @Valid @RequestBody DriverInformation request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey,
                                                    Authentication authentication) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (!canAccessDriver(authentication, driverId)) {
                throw new org.springframework.security.access.AccessDeniedException("Forbidden");
            }
            request.setDriverId(driverId);
            if (useKey) {
                driverInformationService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            DriverInformation updated = driverInformationService.updateDriver(request);
            if (useKey && updated.getDriverId() != null) {
                driverInformationService.markHistorySuccess(idempotencyKey, updated.getDriverId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                driverInformationService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update driver failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @DeleteMapping("/{driverId}")
    @Operation(summary = "删除驾驶员档案")
    public ResponseEntity<Void> delete(@PathVariable Long driverId) {
        try {
            driverInformationService.deleteDriver(driverId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete driver failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/{driverId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @Operation(summary = "查询驾驶员详情")
    public ResponseEntity<DriverInformation> get(@PathVariable Long driverId,
                                                 Authentication authentication) {
        try {
            if (!canAccessDriver(authentication, driverId)) {
                throw new org.springframework.security.access.AccessDeniedException("Forbidden");
            }
            DriverInformation driver = driverInformationService.getDriverById(driverId);
            if (driver == null) {
                throw new com.tutict.finalassignmentbackend.exception.EntityNotFoundException("Driver not found: " + driverId);
            }
            return ResponseEntity.ok(driver);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get driver failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping
    @Operation(summary = "查询全部驾驶员")
    public ResponseEntity<ApiResponse<PageResponse<DriverResponse>>> list(@RequestParam(defaultValue = "0") int page,
                                                                          @RequestParam(defaultValue = "20") int size) {
        try {
            List<DriverResponse> drivers = driverInformationService.getAllDrivers().stream()
                    .map(DriverResponse::from)
                    .collect(Collectors.toList());
            int normalizedPage = Math.max(page, 0);
            int normalizedSize = Math.max(size, 1);
            int from = Math.min(normalizedPage * normalizedSize, drivers.size());
            int to = Math.min(from + normalizedSize, drivers.size());
            return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(
                    drivers.subList(from, to), drivers.size(), normalizedPage, normalizedSize)));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List drivers failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/id-card")
    @Operation(summary = "按身份证号搜索驾驶员")
    public ResponseEntity<List<DriverInformation>> searchByIdCard(@RequestParam String keywords,
                                                                  @RequestParam(defaultValue = "1") int page,
                                                                  @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(driverInformationService.searchByIdCardNumber(keywords, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by id card failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/license")
    @Operation(summary = "按驾驶证号搜索驾驶员")
    public ResponseEntity<List<DriverInformation>> searchByLicense(@RequestParam String keywords,
                                                                   @RequestParam(defaultValue = "1") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(driverInformationService.searchByDriverLicenseNumber(keywords, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by license failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/name")
    @Operation(summary = "按姓名搜索驾驶员")
    public ResponseEntity<List<DriverInformation>> searchByName(@RequestParam String keywords,
                                                                @RequestParam(defaultValue = "1") int page,
                                                                @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(driverInformationService.searchByName(keywords, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by name failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @Operation(summary = "Search drivers by name")
    public ResponseEntity<ApiResponse<List<DriverResponse>>> searchDrivers(@RequestParam(required = false) String name,
                                                                           @RequestParam(required = false) String keywords,
                                                                           @RequestParam(defaultValue = "0") int page,
                                                                           @RequestParam(defaultValue = "20") int size) {
        try {
            String searchTerm = name != null ? name : keywords;
            List<DriverResponse> results = driverInformationService.searchByName(searchTerm, page + 1, size).stream()
                    .map(DriverResponse::from)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.ok(results));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search driver by name failed", ex);
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
