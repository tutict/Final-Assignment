package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Level;

@RestController
@RequestMapping("/api/offenses")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Offense Information", description = "APIs for managing offense information records")
public class OffenseInformationController {

    private static final Logger logger = Logger.getLogger(OffenseInformationController.class.getName());

    private final OffenseInformationService offenseInformationService;

    public OffenseInformationController(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "创建违法行为记录",
            description = "管理员创建新的违法行为记录，需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "违法行为记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "409", description = "重复请求，幂等键冲突"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createOffense(
            @RequestBody @Parameter(description = "违法行为记录的详细信息", required = true) OffenseInformation offenseInformation,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            offenseInformationService.checkAndInsertIdempotency(idempotencyKey, offenseInformation, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(null);
        }
    }

    @GetMapping("/{offenseId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取违法行为记录",
            description = "获取指定ID的违法行为记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违法行为记录"),
            @ApiResponse(responseCode = "400", description = "无效的违法行为ID"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到违法行为记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<OffenseInformation> getOffenseByOffenseId(
            @PathVariable @Parameter(description = "违法行为ID", required = true) int offenseId) {
        try {
            OffenseInformation offenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
            if (offenseInformation != null) {
                return ResponseEntity.ok(offenseInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有违法行为记录",
            description = "获取所有违法行为记录的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违法行为记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OffenseInformation>> getOffensesInformation() {
        List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
        return ResponseEntity.ok(offensesInformation);
    }

    @PutMapping("/{offenseId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新违法行为记录",
            description = "管理员更新指定ID的违法行为记录，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "违法行为记录更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到违法行为记录"),
            @ApiResponse(responseCode = "409", description = "重复请求，幂等键冲突"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<OffenseInformation> updateOffense(
            @PathVariable @Parameter(description = "违法行为ID", required = true) int offenseId,
            @RequestBody @Parameter(description = "更新后的违法行为记录信息", required = true) OffenseInformation updatedOffenseInformation,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        try {
            OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
            if (existingOffenseInformation != null) {
                updatedOffenseInformation.setOffenseId(offenseId);
                offenseInformationService.checkAndInsertIdempotency(idempotencyKey, updatedOffenseInformation, "update");
                return ResponseEntity.ok(updatedOffenseInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
    }

    @DeleteMapping("/{offenseId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "删除违法行为记录",
            description = "管理员删除指定ID的违法行为记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "违法行为记录删除成功"),
            @ApiResponse(responseCode = "400", description = "无效的违法行为ID"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteOffense(
            @PathVariable @Parameter(description = "违法行为ID", required = true) int offenseId) {
        try {
            offenseInformationService.deleteOffense(offenseId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据时间范围获取违法行为记录",
            description = "获取指定时间范围内的违法行为记录列表，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违法行为记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OffenseInformation>> getOffensesByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") @Parameter(description = "开始时间，格式：yyyy-MM-dd", example = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") @Parameter(description = "结束时间，格式：yyyy-MM-dd", example = "2100-01-01") Date endTime) {
        try {
            List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
            return ResponseEntity.ok(offenses);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/by-offense-type")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "按违法行为类型搜索记录",
            description = "分页搜索包含指定违法行为类型的记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违法行为记录列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的违法行为记录"),
            @ApiResponse(responseCode = "400", description = "无效的搜索或分页参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OffenseInformation>> searchByOffenseType(
            @RequestParam @Parameter(description = "违法行为类型查询字符串", required = true) String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码，从1开始", example = "1") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数", example = "10") int size) {
        logger.log(Level.INFO, "Received request to search offenses by offense type: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});
        try {
            List<OffenseInformation> results = offenseInformationService.searchOffenseType(query, page, size);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No offenses found for offense type: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} offenses for offense type: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for offense type search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by offense type: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    @GetMapping("/by-driver-name")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "按司机姓名搜索违法行为记录",
            description = "分页搜索包含指定司机姓名的违法行为记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违法行为记录列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的违法行为记录"),
            @ApiResponse(responseCode = "400", description = "无效的搜索或分页参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OffenseInformation>> searchByDriverName(
            @RequestParam @Parameter(description = "司机姓名查询字符串", required = true) String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码，从1开始", example = "1") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数", example = "10") int size) {
        logger.log(Level.INFO, "Received request to search offenses by driver name: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});
        try {
            List<OffenseInformation> results = offenseInformationService.searchByDriverName(query, page, size);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No offenses found for driver name: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} offenses for driver name: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for driver name search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by driver name: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    @GetMapping("/by-license-plate")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "按车牌号搜索违法行为记录",
            description = "分页搜索包含指定车牌号的违法行为记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违法行为记录列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的违法行为记录"),
            @ApiResponse(responseCode = "400", description = "无效的搜索或分页参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OffenseInformation>> searchByLicensePlate(
            @RequestParam @Parameter(description = "车牌号查询字符串", required = true) String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码，从1开始", example = "1") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数", example = "10") int size) {
        logger.log(Level.INFO, "Received request to search offenses by license plate: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});
        try {
            List<OffenseInformation> results = offenseInformationService.searchLicensePlate(query, page, size);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No offenses found for license plate: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} offenses for license plate: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for license plate search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by license plate: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }
}