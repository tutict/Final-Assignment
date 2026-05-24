package com.tutict.finalassignmentbackend.controller.business;

import com.tutict.finalassignmentbackend.config.security.SecurityRoleUtils;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;

import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.entity.driver.DriverVehicle;
import com.tutict.finalassignmentbackend.entity.driver.VehicleInformation;
import com.tutict.finalassignmentbackend.service.auth.AuthWsService;
import com.tutict.finalassignmentbackend.service.driver.DriverVehicleService;
import com.tutict.finalassignmentbackend.service.driver.VehicleInformationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import jakarta.validation.Valid;
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
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/vehicles")
@Tag(name = "Vehicle Information", description = "车辆档案与绑定管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class VehicleInformationController {

    private static final Logger LOG = Logger.getLogger(VehicleInformationController.class.getName());
    private static final Set<String> ELEVATED_ROLES = Set.of(
            "SUPER_ADMIN",
            "ADMIN",
            "TRAFFIC_POLICE"
    );

    private final AuthWsService authWsService;
    private final VehicleInformationService vehicleInformationService;
    private final DriverVehicleService driverVehicleService;

    public VehicleInformationController(AuthWsService authWsService,
                                        VehicleInformationService vehicleInformationService,
                                        DriverVehicleService driverVehicleService) {
        this.authWsService = authWsService;
        this.vehicleInformationService = vehicleInformationService;
        this.driverVehicleService = driverVehicleService;
    }

    @PostMapping
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @Operation(summary = "创建车辆档案")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createVehicle(@Valid @RequestBody Map<String, Object> payload,
                                                            @RequestHeader(value = "Idempotency-Key", required = false)
                                                            String idempotencyKey,
                                                            Authentication authentication) {
        try {
            VehicleInformation request = toVehicleInformation(payload);
            Long driverId = resolveRequestedDriverId(authentication, asLong(payload.get("driverId")));
            if (isRegularUser(authentication) && driverId == null) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(ApiResponse.error("DRIVER_PROFILE_NOT_LINKED", "Driver profile is not linked"));
            }
            request.setDriverId(driverId);
            if (hasKey(idempotencyKey)) {
                vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            VehicleInformation saved = vehicleInformationService.createVehicleInformation(request);
            bindVehicleToDriver(saved, driverId);
            Map<String, Object> response = new java.util.LinkedHashMap<>();
            response.put("vehicleId", saved.getVehicleId());
            response.put("licensePlate", saved.getLicensePlate());
            response.put("vehicleType", saved.getVehicleType());
            response.put("ownerName", saved.getOwnerName());
            response.put("driverId", saved.getDriverId());
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(response));
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Create vehicle failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @PutMapping("/{vehicleId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @Operation(summary = "更新车辆档案")
    public ResponseEntity<VehicleInformation> updateVehicle(@PathVariable Long vehicleId,
                                                            @Valid @RequestBody VehicleInformation request,
                                                            @RequestHeader(value = "Idempotency-Key", required = false)
                                                            String idempotencyKey,
                                                            Authentication authentication) {
        try {
            VehicleInformation existing = vehicleInformationService.getVehicleInformationById(vehicleId);
            if (existing == null) {
                throw new com.tutict.finalassignmentbackend.exception.EntityNotFoundException("Vehicle not found: " + vehicleId);
            }
            if (!canAccessDriver(authentication, existing.getDriverId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
            request.setVehicleId(vehicleId);
            request.setDriverId(existing.getDriverId());
            if (hasKey(idempotencyKey)) {
                vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            VehicleInformation updated = vehicleInformationService.updateVehicleInformation(request);
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Update vehicle failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @DeleteMapping("/{vehicleId}")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @Operation(summary = "删除车辆档案")
    public ResponseEntity<Void> deleteVehicle(@PathVariable Long vehicleId,
                                              Authentication authentication) {
        try {
            VehicleInformation existing = vehicleInformationService.getVehicleInformationById(vehicleId);
            if (existing == null) {
                throw new com.tutict.finalassignmentbackend.exception.EntityNotFoundException("Vehicle not found: " + vehicleId);
            }
            if (!canAccessDriver(authentication, existing.getDriverId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
            vehicleInformationService.deleteVehicleInformation(vehicleId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete vehicle failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @DeleteMapping("/license/{licensePlate}")
    @Operation(summary = "根据车牌删除车辆档案")
    public ResponseEntity<Void> deleteVehicleByLicense(@PathVariable String licensePlate) {
        try {
            vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete vehicle by license failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/{vehicleId}")
    @Operation(summary = "查询车辆详情")
    public ResponseEntity<VehicleInformation> getVehicle(@PathVariable Long vehicleId) {
        try {
            VehicleInformation vehicle = vehicleInformationService.getVehicleInformationById(vehicleId);
            if (vehicle == null) {
                throw new com.tutict.finalassignmentbackend.exception.EntityNotFoundException("Vehicle not found: " + vehicleId);
            }
            return ResponseEntity.ok(vehicle);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get vehicle failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping
    @Operation(summary = "查询全部车辆")
    public ResponseEntity<List<VehicleInformation>> listVehicles() {
        try {
            return ResponseEntity.ok(vehicleInformationService.getAllVehicleInformation());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List vehicles failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/license")
    @Operation(summary = "按车牌号搜索车辆")
    public ResponseEntity<VehicleInformation> searchByLicense(@RequestParam String licensePlate) {
        try {
            VehicleInformation vehicle = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
            if (vehicle == null) {
                throw new com.tutict.finalassignmentbackend.exception.EntityNotFoundException("Vehicle not found: " + licensePlate);
            }
            return ResponseEntity.ok(vehicle);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by license failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/owner")
    @Operation(summary = "按车主身份证号查询车辆")
    public ResponseEntity<List<VehicleInformation>> searchByOwnerIdCard(@RequestParam String idCard) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByIdCardNumber(idCard));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by id card failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/type")
    @Operation(summary = "按车辆类型查询")
    public ResponseEntity<List<VehicleInformation>> searchByType(@RequestParam String type) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByType(type));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by type failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/owner/name")
    @Operation(summary = "按车主姓名查询车辆")
    public ResponseEntity<List<VehicleInformation>> searchByOwnerName(@RequestParam String ownerName) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByOwnerName(ownerName));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by owner name failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/status")
    @Operation(summary = "按车辆状态查询")
    public ResponseEntity<List<VehicleInformation>> searchByStatus(@RequestParam String status) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByStatus(status));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by status failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/general")
    @Operation(summary = "关键字分页搜索车辆")
    public ResponseEntity<List<VehicleInformation>> searchVehicles(@RequestParam String keywords,
                                                                   @RequestParam(defaultValue = "1") int page,
                                                                   @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(vehicleInformationService.searchVehicles(keywords, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "General vehicle search failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @PostMapping("/{vehicleId}/drivers")
    @Operation(summary = "创建车辆与驾驶员的绑定")
    public ResponseEntity<?> bindDriver(@PathVariable Long vehicleId,
                                                    @Valid @RequestBody DriverVehicle relation,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setVehicleId(vehicleId);
            if (useKey) {
                if (driverVehicleService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).body(ApiResponse.ok(null));
                }
                driverVehicleService.checkAndInsertIdempotency(idempotencyKey, relation, "create");
            }
            DriverVehicle saved = driverVehicleService.createBinding(relation);
            if (useKey && saved.getId() != null) {
                driverVehicleService.markHistorySuccess(idempotencyKey, saved.getId());
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            if (useKey) {
                driverVehicleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Create driver-vehicle binding failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/{vehicleId}/drivers")
    @Operation(summary = "查询车辆绑定的驾驶员")
    public ResponseEntity<List<DriverVehicle>> listBindings(@PathVariable Long vehicleId,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(driverVehicleService.findByVehicleId(vehicleId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List driver-vehicle binding failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @DeleteMapping("/bindings/{bindingId}")
    @Operation(summary = "删除车辆与驾驶员的绑定")
    public ResponseEntity<Void> deleteBinding(@PathVariable Long bindingId) {
        try {
            driverVehicleService.deleteBinding(bindingId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete driver-vehicle binding failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @PutMapping("/bindings/{bindingId}")
    @Operation(summary = "更新车辆与驾驶员的绑定")
    public ResponseEntity<DriverVehicle> updateBinding(@PathVariable Long bindingId,
                                                       @Valid @RequestBody DriverVehicle relation,
                                                       @RequestHeader(value = "Idempotency-Key", required = false)
                                                       String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setId(bindingId);
            if (useKey) {
                driverVehicleService.checkAndInsertIdempotency(idempotencyKey, relation, "update");
            }
            DriverVehicle updated = driverVehicleService.updateBinding(relation);
            if (useKey && updated.getId() != null) {
                driverVehicleService.markHistorySuccess(idempotencyKey, updated.getId());
            }
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            if (useKey) {
                driverVehicleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            }
            LOG.log(Level.SEVERE, "Update driver-vehicle binding failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/bindings/{bindingId}")
    @Operation(summary = "查询绑定详情")
    public ResponseEntity<DriverVehicle> getBinding(@PathVariable Long bindingId) {
        try {
            DriverVehicle binding = driverVehicleService.findById(bindingId);
            if (binding == null) {
                throw new com.tutict.finalassignmentbackend.exception.EntityNotFoundException("Vehicle binding not found: " + bindingId);
            }
            return ResponseEntity.ok(binding);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get driver-vehicle binding failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/bindings")
    @Operation(summary = "查询全部绑定关系")
    public ResponseEntity<List<DriverVehicle>> listBindingsOverview() {
        try {
            return ResponseEntity.ok(driverVehicleService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List driver-vehicle bindings failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/drivers/{driverId}/vehicles")
    @Operation(summary = "按驾驶员查询绑定的车辆")
    public ResponseEntity<List<DriverVehicle>> listByDriver(@PathVariable Long driverId,
                                                            @RequestParam(defaultValue = "1") int page,
                                                            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(driverVehicleService.findByDriverId(driverId, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List driver bindings failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/drivers/{driverId}/records")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @Operation(summary = "按驾驶员查询车辆档案")
    public ResponseEntity<List<VehicleInformation>> listVehicleRecordsByDriver(
            @PathVariable Long driverId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication) {
        if (!canAccessDriver(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByDriverId(driverId, page, size));
    }

    @GetMapping("/drivers/{driverId}/vehicles/primary")
    @Operation(summary = "查询驾驶员的主绑定车辆")
    public ResponseEntity<List<DriverVehicle>> primaryBinding(@PathVariable Long driverId) {
        try {
            return ResponseEntity.ok(driverVehicleService.findPrimaryBinding(driverId));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get primary binding failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/bindings/search/relationship")
    @Operation(summary = "按关系类型搜索绑定")
    public ResponseEntity<List<DriverVehicle>> searchByRelationship(@RequestParam String relationship,
                                                                    @RequestParam(defaultValue = "1") int page,
                                                                    @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseEntity.ok(driverVehicleService.searchByRelationship(relationship, page, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search bindings by relationship failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/search/license/global")
    @Operation(summary = "获取全局车牌补全建议")
    public ResponseEntity<List<String>> globalPlateSuggestions(@RequestParam String prefix,
                                                               @RequestParam(defaultValue = "10") int size) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByLicensePlateGlobally(prefix, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch global plate suggestions failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/autocomplete/plates")
    @Operation(summary = "获取指定车主的车牌补全建议")
    public ResponseEntity<List<String>> plateAutocomplete(@RequestParam String prefix,
                                                          @RequestParam(defaultValue = "10") int size,
                                                          @RequestParam String idCard) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getLicensePlateAutocompleteSuggestions(prefix, size, idCard));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch plate autocomplete failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/autocomplete")
    @RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "USER"})
    @Operation(summary = "Autocomplete license plates by prefix")
    public ResponseEntity<ApiResponse<List<String>>> autocompletePlates(@RequestParam String prefix,
                                                                        @RequestParam(defaultValue = "10") int limit) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(vehicleInformationService.suggestPlates(prefix, limit)));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch plate autocomplete failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/autocomplete/types")
    @Operation(summary = "获取指定车主的车辆类型补全")
    public ResponseEntity<List<String>> vehicleTypeAutocomplete(@RequestParam String idCard,
                                                                @RequestParam String prefix,
                                                                @RequestParam(defaultValue = "10") int size) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleTypeAutocompleteSuggestions(idCard, prefix, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch vehicle type autocomplete failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/autocomplete/types/global")
    @Operation(summary = "全局车辆类型补全建议")
    public ResponseEntity<List<String>> vehicleTypeAutocompleteGlobal(@RequestParam String prefix,
                                                                      @RequestParam(defaultValue = "10") int size) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleTypesByPrefixGlobally(prefix, size));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Fetch global vehicle type autocomplete failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    @GetMapping("/exists/{licensePlate}")
    @Operation(summary = "检查车辆是否存在")
    public ResponseEntity<Map<String, Boolean>> licenseExists(@PathVariable String licensePlate) {
        try {
            boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
            return ResponseEntity.ok(Map.of("exists", exists));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "License plate existence check failed", ex);
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException(ex);
        }
    }

    private boolean hasKey(String value) {
        return value != null && !value.isBlank();
    }

    private VehicleInformation toVehicleInformation(Map<String, Object> payload) {
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setDriverId(asLong(payload.get("driverId")));
        vehicle.setLicensePlate(asString(payload.get("licensePlate")));
        vehicle.setPlateColor(asString(payload.get("plateColor")));
        vehicle.setVehicleType(asString(payload.get("vehicleType")));
        vehicle.setBrand(asString(payload.get("brand")));
        vehicle.setModel(asString(payload.get("model")));
        vehicle.setVehicleColor(asString(payload.get("vehicleColor")));
        vehicle.setEngineNumber(asString(payload.get("engineNumber")));
        vehicle.setFrameNumber(asString(payload.get("frameNumber")));
        vehicle.setOwnerName(asString(payload.get("ownerName")));
        vehicle.setOwnerIdCard(asString(firstPresent(payload, "ownerIdCard", "idCardNumber")));
        vehicle.setOwnerContact(asString(firstPresent(payload, "ownerContact", "contactNumber")));
        vehicle.setOwnerAddress(asString(payload.get("ownerAddress")));
        vehicle.setFirstRegistrationDate(parseDate(payload.get("firstRegistrationDate")));
        vehicle.setRegistrationDate(parseDate(payload.get("registrationDate")));
        vehicle.setIssuingAuthority(asString(payload.get("issuingAuthority")));
        vehicle.setStatus(asString(firstPresent(payload, "status", "currentStatus")));
        vehicle.setInspectionExpiryDate(parseDate(payload.get("inspectionExpiryDate")));
        vehicle.setInsuranceExpiryDate(parseDate(payload.get("insuranceExpiryDate")));
        vehicle.setCreatedBy(asString(payload.get("createdBy")));
        vehicle.setUpdatedBy(asString(payload.get("updatedBy")));
        vehicle.setRemarks(asString(payload.get("remarks")));
        return vehicle;
    }

    private Long resolveRequestedDriverId(Authentication authentication, Long requestedDriverId) {
        if (isElevated(authentication)) {
            return requestedDriverId;
        }
        UserProfileResponse profile = authWsService.getCurrentUserProfile(authentication.getName());
        return profile.getDriverId();
    }

    private void bindVehicleToDriver(VehicleInformation vehicle, Long driverId) {
        if (vehicle == null || vehicle.getVehicleId() == null || driverId == null) {
            return;
        }
        DriverVehicle relation = new DriverVehicle();
        relation.setVehicleId(vehicle.getVehicleId());
        relation.setDriverId(driverId);
        relation.setRelationship("Owner");
        relation.setIsPrimary(false);
        relation.setStatus("Active");
        driverVehicleService.createBinding(relation);
    }

    private boolean canAccessDriver(Authentication authentication, Long driverId) {
        if (authentication == null) {
            return false;
        }
        if (isElevated(authentication)) {
            return true;
        }
        if (driverId == null) {
            return false;
        }
        UserProfileResponse profile = authWsService.getCurrentUserProfile(authentication.getName());
        return Objects.equals(profile.getDriverId(), driverId);
    }

    private boolean isRegularUser(Authentication authentication) {
        return authentication != null
                && !isElevated(authentication)
                && SecurityRoleUtils.hasRole(authentication, "USER");
    }

    private boolean isElevated(Authentication authentication) {
        return authentication != null
                && SecurityRoleUtils.hasAnyRole(authentication, ELEVATED_ROLES);
    }

    private Object firstPresent(Map<String, Object> payload, String firstKey, String secondKey) {
        Object first = payload.get(firstKey);
        return first != null ? first : payload.get(secondKey);
    }

    private String asString(Object value) {
        return value == null ? null : value.toString();
    }

    private Long asLong(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.longValue();
        }
        try {
            return Long.parseLong(value.toString());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private java.time.LocalDate parseDate(Object value) {
        return value == null ? null : java.time.LocalDate.parse(value.toString());
    }

    private HttpStatus resolveStatus(Exception ex) {
        return (ex instanceof IllegalArgumentException || ex instanceof IllegalStateException)
                ? HttpStatus.BAD_REQUEST
                : HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
