package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Level;

@RestController
@RequestMapping("/api/drivers")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Driver Information", description = "APIs for managing driver information records")
public class DriverInformationController {

    private static final Logger logger = Logger.getLogger(DriverInformationController.class.getName());

    private final DriverInformationService driverInformationService;
    private final UserManagementService userManagementService;

    public DriverInformationController(
            DriverInformationService driverInformationService,
            UserManagementService userManagementService) {
        this.driverInformationService = driverInformationService;
        this.userManagementService = userManagementService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "创建司机信息",
            description = "创建新的司机信息记录，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "司机信息创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "409", description = "重复请求，幂等键冲突"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createDriver(
            @RequestBody @Parameter(description = "司机信息的详细信息", required = true) DriverInformation driverInformation,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, driverInformation, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{driverId}")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "根据ID获取司机信息",
            description = "获取指定ID的司机信息，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回司机信息"),
            @ApiResponse(responseCode = "400", description = "无效的司机ID"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到司机信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<DriverInformation> getDriverById(
            @PathVariable @Parameter(description = "司机ID", required = true) int driverId) {
        try {
            DriverInformation driverInformation = driverInformationService.getDriverById(driverId);
            if (driverInformation != null) {
                return ResponseEntity.ok(driverInformation);
            }
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "获取所有司机信息",
            description = "获取所有司机信息的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回司机信息列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DriverInformation>> getAllDrivers() {
        List<DriverInformation> drivers = driverInformationService.getAllDrivers();
        return ResponseEntity.ok(drivers);
    }

    @PutMapping("/{driverId}/name")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "更新司机姓名",
            description = "更新指定ID司机的姓名，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交，同时更新用户管理记录的修改时间。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "司机姓名更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到司机信息"),
            @ApiResponse(responseCode = "409", description = "重复请求，幂等键冲突"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updateDriverName(
            @PathVariable @Parameter(description = "司机ID", required = true) int driverId,
            @RequestBody @Parameter(description = "新的司机姓名", required = true) String name,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            DriverInformation existingDriver = driverInformationService.getDriverById(driverId);
            if (existingDriver == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            existingDriver.setName(name);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, existingDriver, "update");
            updateUserManagementModifiedTime(driverId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PutMapping("/{driverId}/contactNumber")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "更新司机联系电话",
            description = "更新指定ID司机的联系电话，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交，同时更新用户管理记录的修改时间。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "司机联系电话更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到司机信息"),
            @ApiResponse(responseCode = "409", description = "重复请求，幂等键冲突"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updateDriverContactNumber(
            @PathVariable @Parameter(description = "司机ID", required = true) int driverId,
            @RequestBody @Parameter(description = "新的联系电话", required = true) String contactNumber,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            DriverInformation existingDriver = driverInformationService.getDriverById(driverId);
            if (existingDriver == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            existingDriver.setContactNumber(contactNumber);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, existingDriver, "update");
            updateUserManagementModifiedTime(driverId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PutMapping("/{driverId}/idCardNumber")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "更新司机身份证号码",
            description = "更新指定ID司机的身份证号码，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交，同时更新用户管理记录的修改时间。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "司机身份证号码更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到司机信息"),
            @ApiResponse(responseCode = "409", description = "重复请求，幂等键冲突"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updateDriverIdCardNumber(
            @PathVariable @Parameter(description = "司机ID", required = true) int driverId,
            @RequestBody @Parameter(description = "新的身份证号码", required = true) String idCardNumber,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            DriverInformation existingDriver = driverInformationService.getDriverById(driverId);
            if (existingDriver == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            existingDriver.setIdCardNumber(idCardNumber);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, existingDriver, "update");
            updateUserManagementModifiedTime(driverId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PutMapping("/{driverId}")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "更新司机完整信息",
            description = "更新指定ID司机的完整信息，USER 和 ADMIN 角色均可访问。需要提供幂等键以防止重复提交，同时更新用户管理记录的修改时间。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "司机信息更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到司机信息"),
            @ApiResponse(responseCode = "409", description = "重复请求，幂等键冲突"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updateDriver(
            @PathVariable @Parameter(description = "司机ID", required = true) int driverId,
            @RequestBody @Parameter(description = "更新后的司机信息", required = true) DriverInformation updatedDriverInformation,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            DriverInformation existingDriver = driverInformationService.getDriverById(driverId);
            if (existingDriver == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            updatedDriverInformation.setDriverId(driverId);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, updatedDriverInformation, "update");
            updateUserManagementModifiedTime(driverId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/{driverId}")
    @PreAuthorize("hasRole('ROLE_ADMIN')")
    @Operation(
            summary = "删除司机信息",
            description = "删除指定ID的司机信息，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "司机信息删除成功"),
            @ApiResponse(responseCode = "400", description = "无效的司机ID"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到司机信息"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteDriver(
            @PathVariable @Parameter(description = "司机ID", required = true) int driverId) {
        try {
            driverInformationService.deleteDriver(driverId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/by-id-card")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "按身份证号码搜索司机信息",
            description = "分页搜索包含指定身份证号码的司机信息，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回司机信息列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的司机信息"),
            @ApiResponse(responseCode = "400", description = "无效的搜索或分页参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DriverInformation>> searchByIdCardNumber(
            @RequestParam @Parameter(description = "身份证号码查询字符串", required = true) String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码，从1开始", example = "1") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数", example = "10") int size) {
        logger.log(Level.INFO, "Received request to search drivers by ID card number: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});
        try {
            List<DriverInformation> results = driverInformationService.searchByIdCardNumber(query, page, size);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No drivers found for ID card number: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} drivers for ID card number: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for ID card search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by ID card number: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    @GetMapping("/by-license-number")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "按驾驶证号搜索司机信息",
            description = "分页搜索包含指定驾驶证号的司机信息，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回司机信息列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的司机信息"),
            @ApiResponse(responseCode = "400", description = "无效的搜索或分页参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DriverInformation>> searchByDriverLicenseNumber(
            @RequestParam @Parameter(description = "驾驶证号查询字符串", required = true) String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码，从1开始", example = "1") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数", example = "10") int size) {
        logger.log(Level.INFO, "Received request to search drivers by driver license number: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});
        try {
            List<DriverInformation> results = driverInformationService.searchByDriverLicenseNumber(query, page, size);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No drivers found for driver license number: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} drivers for driver license number: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for license number search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by driver license number: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    @GetMapping("/by-name")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    @Operation(
            summary = "按姓名搜索司机信息",
            description = "分页搜索包含指定姓名的司机信息，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回司机信息列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的司机信息"),
            @ApiResponse(responseCode = "400", description = "无效的搜索或分页参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DriverInformation>> searchByName(
            @RequestParam @Parameter(description = "司机姓名查询字符串", required = true) String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码，从1开始", example = "1") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数", example = "10") int size) {
        logger.log(Level.INFO, "Received request to search drivers by name: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});
        try {
            List<DriverInformation> results = driverInformationService.searchByName(query, page, size);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No drivers found for name: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} drivers for name: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for name search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by name: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    private void updateUserManagementModifiedTime(int driverId) {
        UserManagement user = userManagementService.getUserById(driverId);
        if (user != null) {
            user.setModifiedTime(LocalDateTime.now());
            userManagementService.updateUser(user);
        } else {
            System.out.println("No UserManagement found for driverId: " + driverId);
        }
    }
}