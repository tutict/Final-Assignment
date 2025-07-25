package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/vehicles")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Vehicle Information", description = "APIs for managing vehicle information")
public class VehicleInformationController {

    private static final Logger log = Logger.getLogger(VehicleInformationController.class.getName());

    private final VehicleInformationService vehicleInformationService;

    public VehicleInformationController(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "搜索车辆信息",
            description = "根据查询字符串搜索车辆信息，支持分页，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆信息列表"),
            @ApiResponse(responseCode = "400", description = "无效的搜索参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<VehicleInformation>> searchVehicles(
            @RequestParam @Parameter(description = "搜索查询字符串", required = true, example = "ABC123") String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码（从 1 开始）", example = "1") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数", example = "10") int size) {
        try {
            List<VehicleInformation> vehicles = vehicleInformationService.searchVehicles(query, page, size);
            return ResponseEntity.ok(vehicles);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid search parameters: " + e.getMessage());
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @GetMapping("/autocomplete/license-plate/me")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取车牌号自动补全建议",
            description = "根据前缀和身份证号获取车牌号自动补全建议，USER 和 ADMIN 角色均可访问。返回的建议列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车牌号建议列表"),
            @ApiResponse(responseCode = "400", description = "无效的身份证号或前缀"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getLicensePlateAutocompleteSuggestions(
            @RequestParam @Parameter(description = "车牌号前缀", required = true, example = "ABC") String prefix,
            @RequestParam(defaultValue = "5") @Parameter(description = "最大建议数量", example = "5") int maxSuggestions,
            @RequestParam @Parameter(description = "身份证号", required = true, example = "123456789012345678") String idCardNumber) {
        Logger log = Logger.getLogger(this.getClass().getName());
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        log.log(Level.INFO, "Fetching license plate suggestions for user: {0}, prefix: {1}, maxSuggestions: {2}, idCardNumber: {3}",
                new Object[]{currentUsername, prefix, maxSuggestions, idCardNumber});

        if (idCardNumber == null || idCardNumber.trim().isEmpty()) {
            log.log(Level.WARNING, "Invalid idCardNumber provided for user: {0}", new Object[]{currentUsername});
            return ResponseEntity.badRequest().body(List.of());
        }

        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        String decodedIdCardNumber = URLDecoder.decode(idCardNumber, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Decoded prefix: {0}, idCardNumber: {1}", new Object[]{decodedPrefix, decodedIdCardNumber});

        List<String> suggestions = vehicleInformationService.getLicensePlateAutocompleteSuggestions(
                decodedIdCardNumber, decodedPrefix, maxSuggestions);

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No license plate suggestions found for prefix: {0} with idCardNumber: {1} for user: {2}",
                    new Object[]{decodedPrefix, decodedIdCardNumber, currentUsername});
        }
        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/vehicle-type/me")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取车辆类型自动补全建议",
            description = "根据前缀和身份证号获取车辆类型自动补全建议，USER 和 ADMIN 角色均可访问。返回的建议列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆类型建议列表"),
            @ApiResponse(responseCode = "400", description = "无效的身份证号或前缀"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getVehicleTypeAutocompleteSuggestions(
            @RequestParam @Parameter(description = "车辆类型前缀", required = true, example = "Sedan") String prefix,
            @RequestParam(defaultValue = "5") @Parameter(description = "最大建议数量", example = "5") int maxSuggestions,
            @RequestParam @Parameter(description = "身份证号", required = true, example = "123456789012345678") String idCardNumber) {
        Logger log = Logger.getLogger(this.getClass().getName());
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        log.log(Level.INFO, "Fetching vehicle type suggestions for user: {0}, prefix: {1}, maxSuggestions: {2}, idCardNumber: {3}",
                new Object[]{currentUsername, prefix, maxSuggestions, idCardNumber});

        if (idCardNumber == null || idCardNumber.trim().isEmpty()) {
            log.log(Level.WARNING, "Invalid idCardNumber provided for user: {0}", new Object[]{currentUsername});
            return ResponseEntity.badRequest().body(List.of());
        }

        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        String decodedIdCardNumber = URLDecoder.decode(idCardNumber, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Decoded prefix: {0}, idCardNumber: {1}", new Object[]{decodedPrefix, decodedIdCardNumber});

        List<String> suggestions = vehicleInformationService.getVehicleTypeAutocompleteSuggestions(
                decodedIdCardNumber, decodedPrefix, maxSuggestions);

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No vehicle type suggestions found for prefix: {0} with idCardNumber: {1} for user: {2}",
                    new Object[]{decodedPrefix, decodedIdCardNumber, currentUsername});
        }
        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/license-plate-globally/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取全局车牌号自动补全建议",
            description = "根据前缀获取全局车牌号自动补全建议，仅限 ADMIN 角色。返回的建议列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车牌号建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的车牌号建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getLicensePlateAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "车牌号前缀", required = true, example = "ABC") String licensePlate) {
        String decodedPrefix = URLDecoder.decode(licensePlate, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching license plate suggestions for prefix: {0}, decoded: {1}",
                new Object[]{licensePlate, decodedPrefix});

        List<String> suggestions = vehicleInformationService.getVehicleInformationByLicensePlateGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No license plate suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} license plate suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/vehicle-type-globally/me")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取全局车辆类型自动补全建议",
            description = "根据前缀获取全局车辆类型自动补全建议，仅限 ADMIN 角色。返回的建议列表已进行 URL 解码。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆类型建议列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的车辆类型建议"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<String>> getVehicleTypeAutocompleteSuggestionsGlobally(
            @RequestParam @Parameter(description = "车辆类型前缀", required = true, example = "Sedan") String vehicleType) {
        String decodedPrefix = URLDecoder.decode(vehicleType, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching vehicle type suggestions for prefix: {0}, decoded: {1}",
                new Object[]{vehicleType, decodedPrefix});

        List<String> suggestions = vehicleInformationService.getVehicleTypesByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No vehicle type suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} vehicle type suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }

    @PostMapping
    @Transactional
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "创建车辆信息",
            description = "创建新的车辆信息记录，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "车辆信息创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "409", description = "重复请求（幂等键冲突）"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createVehicleInformation(
            @Valid @RequestBody @Parameter(description = "车辆信息记录", required = true) VehicleInformation vehicleInformation,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, vehicleInformation, "create");
            log.info("Vehicle created with idempotencyKey: " + idempotencyKey);
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (RuntimeException e) {
            log.log(Level.SEVERE, "Failed to create vehicle: " + e.getMessage(), e);
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{vehicleId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取车辆信息",
            description = "获取指定ID的车辆信息记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆信息"),
            @ApiResponse(responseCode = "400", description = "无效的车辆ID"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到车辆信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<VehicleInformation> getVehicleInformationById(
            @PathVariable @Parameter(description = "车辆ID", required = true) int vehicleId) {
        try {
            VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationById(vehicleId);
            if (vehicleInformation == null) {
                log.info("Vehicle not found for ID: " + vehicleId);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            return ResponseEntity.ok(vehicleInformation);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid vehicle ID: " + vehicleId);
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/license-plate/{licensePlate}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据车牌号获取车辆信息",
            description = "获取指定车牌号的车辆信息记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆信息"),
            @ApiResponse(responseCode = "400", description = "无效的车牌号"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到车辆信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<VehicleInformation> getVehicleInformationByLicensePlate(
            @PathVariable @Parameter(description = "车牌号", required = true) String licensePlate) {
        try {
            VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
            if (vehicleInformation == null) {
                log.info("Vehicle not found for license plate: " + licensePlate);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            return ResponseEntity.ok(vehicleInformation);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid license plate: " + licensePlate);
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有车辆信息",
            description = "获取所有车辆信息记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆信息列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<VehicleInformation>> getAllVehicleInformation() {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getAllVehicleInformation();
        return ResponseEntity.ok(vehicleInformationList);
    }

    @GetMapping("/type/{vehicleType}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据车辆类型获取车辆信息",
            description = "获取指定类型的车辆信息记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆信息列表"),
            @ApiResponse(responseCode = "400", description = "无效的车辆类型"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByType(
            @PathVariable @Parameter(description = "车辆类型（如 Sedan、SUV）", required = true) String vehicleType) {
        try {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByType(vehicleType);
            return ResponseEntity.ok(vehicleInformationList);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid vehicle type: " + vehicleType);
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @GetMapping("/owner/{ownerName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据车主姓名获取车辆信息",
            description = "获取指定车主姓名的车辆信息记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆信息列表"),
            @ApiResponse(responseCode = "400", description = "无效的车主姓名"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByOwnerName(
            @PathVariable @Parameter(description = "车主姓名", required = true) String ownerName) {
        try {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByOwnerName(ownerName);
            return ResponseEntity.ok(vehicleInformationList);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid owner name: " + ownerName);
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @GetMapping("/id-card-number/{idCardNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据身份证号获取车辆信息",
            description = "获取指定身份证号的车辆信息记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆信息列表"),
            @ApiResponse(responseCode = "400", description = "无效的身份证号"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByIdCardNumber(
            @PathVariable @Parameter(description = "身份证号", required = true) String idCardNumber) {
        try {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByIdCardNumber(idCardNumber);
            return ResponseEntity.ok(vehicleInformationList);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid ID card number: " + idCardNumber);
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @GetMapping("/status/{currentStatus}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据状态获取车辆信息",
            description = "获取指定状态的车辆信息记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆信息列表"),
            @ApiResponse(responseCode = "400", description = "无效的状态"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByStatus(
            @PathVariable @Parameter(description = "车辆状态（如 ACTIVE、INACTIVE）", required = true) String currentStatus) {
        try {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByStatus(currentStatus);
            return ResponseEntity.ok(vehicleInformationList);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid current status: " + currentStatus);
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @PutMapping("/{vehicleId}")
    @Transactional
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "更新车辆信息",
            description = "更新指定ID的车辆信息记录，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "车辆信息更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到车辆信息"),
            @ApiResponse(responseCode = "409", description = "重复请求（幂等键冲突）"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<VehicleInformation> updateVehicleInformation(
            @PathVariable @Parameter(description = "车辆ID", required = true) int vehicleId,
            @Valid @RequestBody @Parameter(description = "更新后的车辆信息", required = true) VehicleInformation vehicleInformation,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            vehicleInformation.setVehicleId(vehicleId);
            vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, vehicleInformation, "update");
            log.info("Vehicle updated with ID: " + vehicleId);
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationById(vehicleId));
        } catch (RuntimeException e) {
            log.log(Level.SEVERE, "Failed to update vehicle: " + e.getMessage(), e);
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            } else if (e.getMessage().contains("Vehicle not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/{vehicleId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "根据ID删除车辆信息",
            description = "管理员删除指定ID的车辆信息记录，仅限 ADMIN 角色。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "车辆信息删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到车辆信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteVehicleInformation(
            @PathVariable @Parameter(description = "车辆ID", required = true) int vehicleId) {
        try {
            vehicleInformationService.deleteVehicleInformation(vehicleId);
            log.info("Vehicle deleted with ID: " + vehicleId);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            log.log(Level.SEVERE, "Failed to delete vehicle: " + e.getMessage(), e);
            if (e.getMessage().contains("Vehicle not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/license-plate/{licensePlate}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "根据车牌号删除车辆信息",
            description = "管理员删除指定车牌号的车辆信息记录，仅限 ADMIN 角色。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "车辆信息删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteVehicleInformationByLicensePlate(
            @PathVariable @Parameter(description = "车牌号", required = true) String licensePlate) {
        try {
            vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
            log.info("Vehicle(s) deleted with license plate: " + licensePlate);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            log.log(Level.SEVERE, "Failed to delete vehicle by license plate: " + e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/exists/{licensePlate}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "检查车牌号是否存在",
            description = "检查指定车牌号是否已存在，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "返回车牌号是否存在（true/false）"),
            @ApiResponse(responseCode = "400", description = "无效的车牌号"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Boolean> isLicensePlateExists(
            @PathVariable @Parameter(description = "车牌号", required = true) String licensePlate) {
        try {
            boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
            return ResponseEntity.ok(exists);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid license plate: " + licensePlate);
            return ResponseEntity.badRequest().body(false);
        }
    }
}