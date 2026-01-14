package com.tutict.finalassignmentcloud.traffic.controller;

import com.tutict.finalassignmentcloud.entity.DriverInformation;
import com.tutict.finalassignmentcloud.traffic.service.DriverInformationService;
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
@RequestMapping("/api/drivers")
@Tag(name = "Driver Information", description = "驾驶员档案管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class DriverInformationController {

    private static final Logger LOG = Logger.getLogger(DriverInformationController.class.getName());

    private final DriverInformationService driverInformationService;

    public DriverInformationController(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    @PostMapping
    @Operation(summary = "创建驾驶员档案")
    public ResponseEntity<DriverInformation> create(@RequestBody DriverInformation request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            if (useKey) {
                if (driverInformationService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
                }
                driverInformationService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            DriverInformation saved = driverInformationService.createDriver(request);
            if (useKey && saved.getDriverId() != null) {
                driverInformationService.markHistorySuccess(idempotencyKey, saved.getDriverId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                driverInformationService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create driver failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{driverId}")
    @Operation(summary = "更新驾驶员档案")
    public ResponseEntity<DriverInformation> update(@PathVariable Long driverId,
                                                    @RequestBody DriverInformation request,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{driverId}")
    @Operation(summary = "查询驾驶员详情")
    public ResponseEntity<DriverInformation> get(@PathVariable Long driverId) {
        try {
            DriverInformation driver = driverInformationService.getDriverById(driverId);
            return driver == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(driver);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get driver failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部驾驶员")
    public ResponseEntity<List<DriverInformation>> list() {
        try {
            return ResponseEntity.ok(driverInformationService.getAllDrivers());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List drivers failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
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
