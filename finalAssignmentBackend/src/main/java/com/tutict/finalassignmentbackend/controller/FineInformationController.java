package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
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
@RequestMapping("/api/fines")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Fine Information", description = "APIs for managing fine information records")
public class FineInformationController {

    private static final Logger logger = Logger.getLogger(FineInformationController.class.getName());

    private final FineInformationService fineInformationService;

    public FineInformationController(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "创建罚款记录",
            description = "管理员创建新的罚款记录，需要提供幂等键以防止重复提交。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "罚款记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> createFine(
            @RequestBody @Parameter(description = "罚款记录的详细信息", required = true) FineInformation fineInformation,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        fineInformationService.checkAndInsertIdempotency(idempotencyKey, fineInformation, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{fineId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据ID获取罚款记录",
            description = "获取指定ID的罚款记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回罚款记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到罚款记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<FineInformation> getFineById(
            @PathVariable @Parameter(description = "罚款记录ID", required = true) int fineId) {
        FineInformation fineInformation = fineInformationService.getFineById(fineId);
        if (fineInformation != null) {
            return ResponseEntity.ok(fineInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "获取所有罚款记录",
            description = "获取所有罚款记录的列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回罚款记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<FineInformation>> getAllFines() {
        List<FineInformation> fines = fineInformationService.getAllFines();
        return ResponseEntity.ok(fines);
    }

    @PutMapping("/{fineId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新罚款记录",
            description = "管理员更新指定ID的罚款记录，需要提供幂等键以防止重复提交。操作在事务中执行。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "罚款记录更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数或幂等键冲突"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到罚款记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<FineInformation> updateFine(
            @PathVariable @Parameter(description = "罚款记录ID", required = true) int fineId,
            @RequestBody @Parameter(description = "更新后的罚款记录信息", required = true) FineInformation updatedFineInformation,
            @RequestParam @Parameter(description = "幂等键，用于防止重复提交", required = true) String idempotencyKey) {
        FineInformation existingFineInformation = fineInformationService.getFineById(fineId);
        if (existingFineInformation != null) {
            updatedFineInformation.setFineId(fineId);
            fineInformationService.checkAndInsertIdempotency(idempotencyKey, updatedFineInformation, "update");
            return ResponseEntity.ok(updatedFineInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @DeleteMapping("/{fineId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "删除罚款记录",
            description = "管理员删除指定ID的罚款记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "罚款记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到罚款记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteFine(
            @PathVariable @Parameter(description = "罚款记录ID", required = true) int fineId) {
        fineInformationService.deleteFine(fineId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/payee/{payee}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据支付方获取罚款记录",
            description = "获取指定支付方的罚款记录列表，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回罚款记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<FineInformation>> getFinesByPayee(
            @PathVariable @Parameter(description = "支付方名称", required = true) String payee) {
        List<FineInformation> fines = fineInformationService.getFinesByPayee(payee);
        return ResponseEntity.ok(fines);
    }

    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据时间范围获取罚款记录",
            description = "获取指定时间范围内的罚款记录列表，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回罚款记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<FineInformation>> getFinesByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") @Parameter(description = "开始时间，格式：yyyy-MM-dd", example = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") @Parameter(description = "结束时间，格式：yyyy-MM-dd", example = "2100-01-01") Date endTime) {
        List<FineInformation> fines = fineInformationService.getFinesByTimeRange(startTime, endTime);
        return ResponseEntity.ok(fines);
    }

    @GetMapping("/receiptNumber/{receiptNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据收据编号获取罚款记录",
            description = "获取指定收据编号的罚款记录，USER 和 ADMIN 角色均可访问。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回罚款记录"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到罚款记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<FineInformation> getFineByReceiptNumber(
            @PathVariable @Parameter(description = "收据编号", required = true) String receiptNumber) {
        FineInformation fineInformation = fineInformationService.getFineByReceiptNumber(receiptNumber);
        if (fineInformation != null) {
            return ResponseEntity.ok(fineInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/by-time-range")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "按时间范围搜索罚款记录",
            description = "搜索指定时间范围内的罚款记录，最多返回指定数量的记录，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd'T'HH:mm:ss。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回罚款记录列表"),
            @ApiResponse(responseCode = "204", description = "未找到匹配的罚款记录"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<FineInformation>> searchByFineTimeRange(
            @RequestParam @Parameter(description = "开始时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true) String startTime,
            @RequestParam @Parameter(description = "结束时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true) String endTime,
            @RequestParam(defaultValue = "10") @Parameter(description = "最大返回记录数", example = "10") int maxSuggestions) {
        logger.log(Level.INFO, "Received request to search fines by time range: startTime={0}, endTime={1}, maxSuggestions={2}",
                new Object[]{startTime, endTime, maxSuggestions});
        try {
            List<FineInformation> results = fineInformationService.searchByFineTimeRange(startTime, endTime, maxSuggestions);
            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No fines found for time range: {0} to {1}",
                        new Object[]{startTime, endTime});
                return ResponseEntity.noContent().build();
            }
            logger.log(Level.INFO, "Returning {0} fines for time range: {1} to {2}",
                    new Object[]{results.size(), startTime, endTime});
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by time range: startTime={0}, endTime={1}, error: {2}",
                    new Object[]{startTime, endTime, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }
}