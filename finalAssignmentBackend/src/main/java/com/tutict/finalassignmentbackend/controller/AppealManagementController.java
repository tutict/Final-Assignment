package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
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

import java.time.LocalDateTime;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/appeals")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Appeal Management", description = "APIs for managing appeals related to offenses")
public class AppealManagementController {

    private static final Logger logger = Logger.getLogger(AppealManagementController.class.getName());

    private final AppealManagementService appealManagementService;

    public AppealManagementController(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    @PostMapping
    @PreAuthorize("hasRole('USER')")
    @Operation(summary = "创建新申诉", description = "允许用户创建新的申诉记录，需要提供幂等键以防止重复提交")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "申诉创建成功，返回创建的申诉记录"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<AppealManagement> createAppeal(
            @RequestBody @Parameter(description = "申诉记录的详细信息") AppealManagement appeal,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交") String idempotencyKey) {
        try {
            AppealManagement createdAppeal = appealManagementService.checkAndInsertIdempotency(idempotencyKey, appeal, "create");
            return ResponseEntity.status(HttpStatus.CREATED).body(createdAppeal);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid input for creating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
        } catch (RuntimeException e) {
            logger.severe("Error creating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @GetMapping("/{appealId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "根据ID获取申诉", description = "获取指定ID的申诉记录")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录"),
            @ApiResponse(responseCode = "400", description = "无效的申诉ID"),
            @ApiResponse(responseCode = "404", description = "未找到申诉记录")
    })
    public ResponseEntity<AppealManagement> getAppealById(
            @PathVariable @Parameter(description = "申诉ID") Integer appealId) {
        try {
            AppealManagement appeal = appealManagementService.getAppealById(appealId);
            if (appeal != null) {
                return ResponseEntity.ok(appeal);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid appeal ID: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "获取所有申诉", description = "返回所有申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表")
    })
    public ResponseEntity<List<AppealManagement>> getAllAppeals() {
        List<AppealManagement> appeals = appealManagementService.getAllAppeals();
        return ResponseEntity.ok(appeals);
    }

    @PutMapping("/{appealId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "更新申诉信息", description = "管理员更新指定ID的申诉记录，需要提供幂等键")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "申诉更新成功，返回更新后的记录"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "404", description = "未找到申诉记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<AppealManagement> updateAppeal(
            @PathVariable @Parameter(description = "申诉ID") Integer appealId,
            @RequestBody @Parameter(description = "更新后的申诉信息") AppealManagement updatedAppeal,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交") String idempotencyKey) {
        try {
            AppealManagement existingAppeal = appealManagementService.getAppealById(appealId);
            if (existingAppeal == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            updatedAppeal.setAppealId(appealId);
            AppealManagement updated = appealManagementService.checkAndInsertIdempotency(idempotencyKey, updatedAppeal, "update");
            return ResponseEntity.ok(updated);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid input for updating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (RuntimeException e) {
            logger.severe("Error updating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/{appealId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "删除申诉", description = "管理员删除指定ID的申诉记录")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "申诉删除成功"),
            @ApiResponse(responseCode = "400", description = "无效的申诉ID"),
            @ApiResponse(responseCode = "404", description = "未找到申诉记录")
    })
    public ResponseEntity<Void> deleteAppeal(
            @PathVariable @Parameter(description = "申诉ID") Integer appealId) {
        try {
            appealManagementService.deleteAppeal(appealId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid appeal ID: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (RuntimeException e) {
            logger.severe("Error deleting appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/status/{processStatus}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按处理状态获取申诉", description = "获取指定处理状态的申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的处理状态")
    })
    public ResponseEntity<List<AppealManagement>> getAppealsByProcessStatus(
            @PathVariable @Parameter(description = "处理状态") String processStatus) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid process status: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/name/{appellantName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按申诉人姓名获取申诉", description = "获取指定申诉人姓名的申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的申诉人姓名")
    })
    public ResponseEntity<List<AppealManagement>> getAppealsByAppellantName(
            @PathVariable @Parameter(description = "申诉人姓名") String appellantName) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByAppellantName(appellantName);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid appellant name: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/{appealId}/offense")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "获取申诉相关的违章信息", description = "获取指定申诉ID对应的违章信息")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违章信息"),
            @ApiResponse(responseCode = "400", description = "无效的申诉ID"),
            @ApiResponse(responseCode = "404", description = "未找到违章信息")
    })
    public ResponseEntity<OffenseInformation> getOffenseByAppealId(
            @PathVariable @Parameter(description = "申诉ID") Integer appealId) {
        try {
            OffenseInformation offense = appealManagementService.getOffenseByAppealId(appealId);
            if (offense != null) {
                return ResponseEntity.ok(offense);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid appeal ID: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/id-card/{idCardNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按身份证号获取申诉", description = "获取指定身份证号的申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的身份证号")
    })
    public ResponseEntity<List<AppealManagement>> getAppealsByIdCardNumber(
            @PathVariable @Parameter(description = "身份证号") String idCardNumber) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByIdCardNumber(idCardNumber);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid ID card number: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/contact/{contactNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按联系电话获取申诉", description = "获取指定联系电话的申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的联系电话")
    })
    public ResponseEntity<List<AppealManagement>> getAppealsByContactNumber(
            @PathVariable @Parameter(description = "联系电话") String contactNumber) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByContactNumber(contactNumber);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid contact number: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/offense/{offenseId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按违章ID获取申诉", description = "获取指定违章ID的申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的违章ID")
    })
    public ResponseEntity<List<AppealManagement>> getAppealsByOffenseId(
            @PathVariable @Parameter(description = "违章ID") Integer offenseId) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByOffenseId(offenseId);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid offense ID: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/time-range")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按时间范围获取申诉", description = "获取指定时间范围内的申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "500", description = "时间解析错误")
    })
    public ResponseEntity<List<AppealManagement>> getAppealsByAppealTimeBetween(
            @RequestParam @Parameter(description = "开始时间，格式：yyyy-MM-dd'T'HH:mm:ss") String startTime,
            @RequestParam @Parameter(description = "结束时间，格式：yyyy-MM-dd'T'HH:mm:ss") String endTime) {
        try {
            LocalDateTime start = LocalDateTime.parse(startTime);
            LocalDateTime end = LocalDateTime.parse(endTime);
            List<AppealManagement> appeals = appealManagementService.getAppealsByAppealTimeBetween(start, end);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid time range: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (Exception e) {
            logger.severe("Error parsing time range: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/by-appellant-name")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按申诉人姓名搜索申诉", description = "分页搜索包含指定申诉人姓名的申诉记录")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的申诉记录"),
            @ApiResponse(responseCode = "400", description = "无效的分页参数"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<AppealManagement>> searchByAppellantName(
            @RequestParam @Parameter(description = "搜索的申诉人姓名") String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码，从1开始") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数") int size) {
        logger.log(Level.INFO, "Received request to search appeals by appellant name: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});
        try {
            List<AppealManagement> results = appealManagementService.searchAppealName(query, page, size);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No appeals found for appellant name: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} appeals for appellant name: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for appellant name search: {0}",
                    new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by appellant name: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    @GetMapping("/by-reason")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按申诉原因搜索申诉", description = "分页搜索包含指定申诉原因的申诉记录")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的申诉记录"),
            @ApiResponse(responseCode = "400", description = "无效的分页参数"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<AppealManagement>> searchByAppealReason(
            @RequestParam @Parameter(description = "搜索的申诉原因") String query,
            @RequestParam(defaultValue = "1") @Parameter(description = "页码，从1开始") int page,
            @RequestParam(defaultValue = "10") @Parameter(description = "每页记录数") int size) {
        logger.log(Level.INFO, "Received request to search appeals by reason: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});
        try {
            List<AppealManagement> results = appealManagementService.searchAppealReason(query, page, size);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No appeals found for reason: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} appeals for reason: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for reason search: {0}",
                    new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by reason: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    @GetMapping("/count/status/{processStatus}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "统计指定状态的申诉数量", description = "返回指定处理状态的申诉记录总数")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉数量"),
            @ApiResponse(responseCode = "400", description = "无效的处理状态")
    })
    public ResponseEntity<Long> countAppealsByStatus(
            @PathVariable @Parameter(description = "处理状态") String processStatus) {
        try {
            long count = appealManagementService.countAppealsByStatus(processStatus);
            return ResponseEntity.ok(count);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid process status: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/reason/{reason}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按申诉原因获取申诉", description = "获取包含指定申诉原因的申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的申诉原因")
    })
    public ResponseEntity<List<AppealManagement>> getAppealsByReasonContaining(
            @PathVariable @Parameter(description = "申诉原因") String reason) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByReasonContaining(reason);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid appeal reason: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/status-and-time")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(summary = "按状态和时间范围获取申诉", description = "获取指定处理状态和时间范围内的申诉记录列表")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的参数"),
            @ApiResponse(responseCode = "500", description = "时间解析错误")
    })
    public ResponseEntity<List<AppealManagement>> getAppealsByStatusAndTime(
            @RequestParam @Parameter(description = "处理状态") String processStatus,
            @RequestParam @Parameter(description = "开始时间，格式：yyyy-MM-dd'T'HH:mm:ss") String startTime,
            @RequestParam @Parameter(description = "结束时间，格式：yyyy-MM-dd'T'HH:mm:ss") String endTime) {
        try {
            LocalDateTime start = LocalDateTime.parse(startTime);
            LocalDateTime end = LocalDateTime.parse(endTime);
            List<AppealManagement> appeals = appealManagementService.getAppealsByStatusAndTime(processStatus, start, end);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid parameters: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (Exception e) {
            logger.severe("Error parsing parameters: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}