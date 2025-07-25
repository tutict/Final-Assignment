package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Level;

@RestController
@RequestMapping("/api/deductions")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Deduction Information", description = "APIs for managing deduction information records")
public class DeductionInformationController {

    private static final Logger logger = Logger.getLogger(DeductionInformationController.class.getName());

    private final DeductionInformationService deductionInformationService;

    public DeductionInformationController(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "创建扣除记录",
            description = "管理员创建新的扣除记录，需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "扣除记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createDeduction(
            @RequestBody @Parameter(description = "扣除记录的详细信息", required = true) DeductionInformation deduction,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        logger.info("Attempting to create deduction with idempotency key: " + idempotencyKey);
        deductionInformationService.checkAndInsertIdempotency(idempotencyKey, deduction, "create");
        logger.info("Deduction created successfully.");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{deductionId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取扣除记录",
            description = "获取指定ID的扣除记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回扣除记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到扣除记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<DeductionInformation> getDeductionById(
            @PathVariable @Parameter(description = "扣除记录ID", required = true) int deductionId) {
        DeductionInformation deduction = deductionInformationService.getDeductionById(deductionId);
        if (deduction != null) {
            return ResponseEntity.ok(deduction);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有扣除记录",
            description = "获取所有扣除记录的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回扣除记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DeductionInformation>> getAllDeductions() {
        List<DeductionInformation> deductions = deductionInformationService.getAllDeductions();
        return ResponseEntity.ok(deductions);
    }

    @PutMapping("/{deductionId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新扣除记录",
            description = "管理员更新指定ID的扣除记录，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "扣除记录更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到扣除记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> updateDeduction(
            @PathVariable @Parameter(description = "扣除记录ID", required = true) int deductionId,
            @RequestBody @Parameter(description = "更新后的扣除记录信息", required = true) DeductionInformation updatedDeduction,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        DeductionInformation existingDeduction = deductionInformationService.getDeductionById(deductionId);
        if (existingDeduction != null) {
            existingDeduction.setRemarks(updatedDeduction.getRemarks());
            existingDeduction.setHandler(updatedDeduction.getHandler());
            existingDeduction.setDeductedPoints(updatedDeduction.getDeductedPoints());
            existingDeduction.setDeductionTime(updatedDeduction.getDeductionTime());
            existingDeduction.setApprover(updatedDeduction.getApprover());
            deductionInformationService.checkAndInsertIdempotency(idempotencyKey, existingDeduction, "update");
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{deductionId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "删除扣除记录",
            description = "管理员删除指定ID的扣除记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "扣除记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到扣除记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteDeduction(
            @PathVariable @Parameter(description = "扣除记录ID", required = true) int deductionId) {
        deductionInformationService.deleteDeduction(deductionId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/handler/{handler}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据处理人获取扣除记录",
            description = "获取指定处理人的扣除记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回扣除记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DeductionInformation>> getDeductionsByHandler(
            @PathVariable @Parameter(description = "处理人名称", required = true) String handler) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByHandler(handler);
        return ResponseEntity.ok(deductions);
    }

    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据时间范围获取扣除记录",
            description = "获取指定时间范围内的扣除记录列表，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd'T'HH:mm:ss。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回扣除记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DeductionInformation>> getDeductionsByTimeRange(
            @RequestParam @Parameter(description = "开始时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true) Date startTime,
            @RequestParam @Parameter(description = "结束时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true) Date endTime) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(deductions);
    }

    @GetMapping("/by-handler")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "按处理人搜索扣除记录",
            description = "搜索包含指定处理人的扣除记录，最多返回指定数量的记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回扣除记录列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的扣除记录"),
            @ApiResponse(responseCode = "400", description = "无效的搜索参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DeductionInformation>> searchByHandler(
            @RequestParam @Parameter(description = "处理人名称", required = true) String handler,
            @RequestParam(defaultValue = "10") @Parameter(description = "最大返回记录数", example = "10") int maxSuggestions) {
        logger.log(Level.INFO, "Received request to search deductions by handler: {0}, maxSuggestions: {1}",
                new Object[]{handler, maxSuggestions});
        try {
            List<DeductionInformation> results = deductionInformationService.searchByHandler(handler, maxSuggestions);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No deductions found for handler: {0}", new Object[]{handler});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} deductions for handler: {1}",
                    new Object[]{results.size(), handler});
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by handler: {0}, error: {1}",
                    new Object[]{handler, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    @GetMapping("/by-time-range")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "按时间范围搜索扣除记录",
            description = "搜索指定时间范围内的扣除记录，最多返回指定数量的记录，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd'T'HH:mm:ss。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回扣除记录列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的扣除记录"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<DeductionInformation>> searchByDeductionTimeRange(
            @RequestParam @Parameter(description = "开始时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true) String startTime,
            @RequestParam @Parameter(description = "结束时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true) String endTime,
            @RequestParam(defaultValue = "10") @Parameter(description = "最大返回记录数", example = "10") int maxSuggestions) {
        logger.log(Level.INFO, "Received request to search deductions by time range: startTime={0}, endTime={1}, maxSuggestions={2}",
                new Object[]{startTime, endTime, maxSuggestions});
        try {
            List<DeductionInformation> results = deductionInformationService.searchByDeductionTimeRange(startTime, endTime, maxSuggestions);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No deductions found for time range: {0} to {1}",
                        new Object[]{startTime, endTime});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} deductions for time range: {1} to {2}",
                    new Object[]{results.size(), startTime, endTime});
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by time range: startTime={0}, endTime={1}, error: {2}",
                    new Object[]{startTime, endTime, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }
}