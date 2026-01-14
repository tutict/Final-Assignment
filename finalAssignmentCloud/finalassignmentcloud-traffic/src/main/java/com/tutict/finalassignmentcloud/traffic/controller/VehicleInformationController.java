package com.tutict.finalassignmentcloud.traffic.controller;

import com.tutict.finalassignmentcloud.entity.DriverVehicle;
import com.tutict.finalassignmentcloud.entity.VehicleInformation;
import com.tutict.finalassignmentcloud.traffic.service.DriverVehicleService;
import com.tutict.finalassignmentcloud.traffic.service.VehicleInformationService;
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
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/vehicles")
@Tag(name = "Vehicle Information", description = "车辆档案与绑定管理接口")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE"})
public class VehicleInformationController {

    private static final Logger LOG = Logger.getLogger(VehicleInformationController.class.getName());

    private final VehicleInformationService vehicleInformationService;
    private final DriverVehicleService driverVehicleService;

    public VehicleInformationController(VehicleInformationService vehicleInformationService,
                                        DriverVehicleService driverVehicleService) {
        this.vehicleInformationService = vehicleInformationService;
        this.driverVehicleService = driverVehicleService;
    }

    @PostMapping
    @Operation(summary = "创建车辆档案")
    public ResponseEntity<VehicleInformation> createVehicle(@RequestBody VehicleInformation request,
                                                            @RequestHeader(value = "Idempotency-Key", required = false)
                                                            String idempotencyKey) {
        try {
            if (hasKey(idempotencyKey)) {
                vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, request, "create");
            }
            VehicleInformation saved = vehicleInformationService.createVehicleInformation(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Create vehicle failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/{vehicleId}")
    @Operation(summary = "更新车辆档案")
    public ResponseEntity<VehicleInformation> updateVehicle(@PathVariable Long vehicleId,
                                                            @RequestBody VehicleInformation request,
                                                            @RequestHeader(value = "Idempotency-Key", required = false)
                                                            String idempotencyKey) {
        try {
            request.setVehicleId(vehicleId);
            if (hasKey(idempotencyKey)) {
                vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, request, "update");
            }
            VehicleInformation updated = vehicleInformationService.updateVehicleInformation(request);
            return ResponseEntity.ok(updated);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Update vehicle failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @DeleteMapping("/{vehicleId}")
    @Operation(summary = "删除车辆档案")
    public ResponseEntity<Void> deleteVehicle(@PathVariable Long vehicleId) {
        try {
            vehicleInformationService.deleteVehicleInformation(vehicleId);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Delete vehicle failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/{vehicleId}")
    @Operation(summary = "查询车辆详情")
    public ResponseEntity<VehicleInformation> getVehicle(@PathVariable Long vehicleId) {
        try {
            VehicleInformation vehicle = vehicleInformationService.getVehicleInformationById(vehicleId);
            return vehicle == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(vehicle);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get vehicle failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping
    @Operation(summary = "查询全部车辆")
    public ResponseEntity<List<VehicleInformation>> listVehicles() {
        try {
            return ResponseEntity.ok(vehicleInformationService.getAllVehicleInformation());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List vehicles failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/license")
    @Operation(summary = "按车牌号搜索车辆")
    public ResponseEntity<VehicleInformation> searchByLicense(@RequestParam String licensePlate) {
        try {
            VehicleInformation vehicle = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
            return vehicle == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(vehicle);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by license failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/owner")
    @Operation(summary = "按车主身份证号查询车辆")
    public ResponseEntity<List<VehicleInformation>> searchByOwnerIdCard(@RequestParam String idCard) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByIdCardNumber(idCard));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by id card failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/type")
    @Operation(summary = "按车辆类型查询")
    public ResponseEntity<List<VehicleInformation>> searchByType(@RequestParam String type) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByType(type));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by type failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/owner/name")
    @Operation(summary = "按车主姓名查询车辆")
    public ResponseEntity<List<VehicleInformation>> searchByOwnerName(@RequestParam String ownerName) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByOwnerName(ownerName));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by owner name failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/search/status")
    @Operation(summary = "按车辆状态查询")
    public ResponseEntity<List<VehicleInformation>> searchByStatus(@RequestParam String status) {
        try {
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationByStatus(status));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Search vehicle by status failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PostMapping("/{vehicleId}/drivers")
    @Operation(summary = "创建车辆与驾驶员的绑定")
    public ResponseEntity<DriverVehicle> bindDriver(@PathVariable Long vehicleId,
                                                    @RequestBody DriverVehicle relation,
                                                    @RequestHeader(value = "Idempotency-Key", required = false)
                                                    String idempotencyKey) {
        boolean useKey = hasKey(idempotencyKey);
        try {
            relation.setVehicleId(vehicleId);
            if (useKey) {
                if (driverVehicleService.shouldSkipProcessing(idempotencyKey)) {
                    return ResponseEntity.status(HttpStatus.ALREADY_REPORTED).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @PutMapping("/bindings/{bindingId}")
    @Operation(summary = "更新车辆与驾驶员的绑定")
    public ResponseEntity<DriverVehicle> updateBinding(@PathVariable Long bindingId,
                                                       @RequestBody DriverVehicle relation,
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
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/bindings/{bindingId}")
    @Operation(summary = "查询绑定详情")
    public ResponseEntity<DriverVehicle> getBinding(@PathVariable Long bindingId) {
        try {
            DriverVehicle binding = driverVehicleService.findById(bindingId);
            return binding == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(binding);
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get driver-vehicle binding failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/bindings")
    @Operation(summary = "查询全部绑定关系")
    public ResponseEntity<List<DriverVehicle>> listBindingsOverview() {
        try {
            return ResponseEntity.ok(driverVehicleService.findAll());
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "List driver-vehicle bindings failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
        }
    }

    @GetMapping("/drivers/{driverId}/vehicles/primary")
    @Operation(summary = "查询驾驶员的主绑定车辆")
    public ResponseEntity<List<DriverVehicle>> primaryBinding(@PathVariable Long driverId) {
        try {
            return ResponseEntity.ok(driverVehicleService.findPrimaryBinding(driverId));
        } catch (Exception ex) {
            LOG.log(Level.WARNING, "Get primary binding failed", ex);
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
            return ResponseEntity.status(resolveStatus(ex)).build();
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
