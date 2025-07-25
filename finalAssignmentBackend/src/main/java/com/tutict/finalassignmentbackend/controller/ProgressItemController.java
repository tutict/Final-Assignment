package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.ProgressItem;
import com.tutict.finalassignmentbackend.service.ProgressItemService;
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

@RestController
@RequestMapping("/api/progress")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Progress Item", description = "APIs for managing progress item records")
public class ProgressItemController {

    private static final Logger logger = Logger.getLogger(ProgressItemController.class.getName());

    private final ProgressItemService progressItemService;

    public ProgressItemController(ProgressItemService progressItemService) {
        this.progressItemService = progressItemService;
    }

    @PostMapping
    @PreAuthorize("hasRole('USER')")
    @Operation(
            summary = "创建进度记录",
            description = "创建新的进度记录，仅限 USER 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "进度记录创建成功"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 USER 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<ProgressItem> createProgress(
            @RequestBody @Parameter(description = "进度记录的详细信息", required = true) ProgressItem progressItem) {
        logger.info("Attempting to create progress item with title: " + progressItem.getTitle());
        ProgressItem savedItem = progressItemService.createProgress(progressItem);
        logger.info("Progress item created successfully with ID: " + savedItem.getId());
        return new ResponseEntity<>(savedItem, HttpStatus.CREATED);
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "获取所有进度记录",
            description = "获取所有进度记录的列表，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回进度记录列表"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<ProgressItem>> getAllProgress() {
        List<ProgressItem> progressItems = progressItemService.getAllProgress();
        return ResponseEntity.ok(progressItems);
    }

    @GetMapping(params = "username")
    @PreAuthorize("hasRole('USER')")
    @Operation(
            summary = "根据用户名获取进度记录",
            description = "获取指定用户名的进度记录列表，仅限 USER 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回进度记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的用户名"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 USER 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<ProgressItem>> getProgressByUsername(
            @RequestParam @Parameter(description = "用户名", required = true) String username) {
        List<ProgressItem> progressItems = progressItemService.getProgressByUsername(username);
        return ResponseEntity.ok(progressItems);
    }

    @PutMapping("/{progressId}/status")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "更新进度记录状态",
            description = "管理员更新指定ID的进度记录状态，仅限 ADMIN 角色。有效状态包括：PENDING、PROCESSING、COMPLETED、ARCHIVED。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "进度记录状态更新成功"),
            @ApiResponse(responseCode = "400", description = "无效的状态参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到进度记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<ProgressItem> updateProgressStatus(
            @PathVariable @Parameter(description = "进度记录ID", required = true) int progressId,
            @RequestParam @Parameter(description = "新状态（PENDING, PROCESSING, COMPLETED, ARCHIVED）", required = true) String newStatus) {
        try {
            ProgressItem updatedItem = progressItemService.updateProgressStatus(progressId, newStatus);
            if (updatedItem != null) {
                logger.info("Progress item with ID " + progressId + " updated successfully to status: " + newStatus);
                return ResponseEntity.ok(updatedItem);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid status provided: " + newStatus);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
        } catch (Exception e) {
            logger.severe("Error updating progress status: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @DeleteMapping("/{progressId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(
            summary = "删除进度记录",
            description = "管理员删除指定ID的进度记录，仅限 ADMIN 角色。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "进度记录删除成功"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "404", description = "未找到进度记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Void> deleteProgress(
            @PathVariable @Parameter(description = "进度记录ID", required = true) int progressId) {
        progressItemService.deleteProgress(progressId);
        logger.info("Progress item with ID " + progressId + " deleted successfully.");
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据状态获取进度记录",
            description = "获取指定状态的进度记录列表，USER 和 ADMIN 角色均可访问。有效状态包括：PENDING、PROCESSING、COMPLETED、ARCHIVED。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回进度记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的状态参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<ProgressItem>> getProgressByStatus(
            @PathVariable @Parameter(description = "状态（PENDING, PROCESSING, COMPLETED, ARCHIVED）", required = true) String status) {
        if (!isValidStatus(status)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        List<ProgressItem> progressItems = progressItemService.getProgressByStatus(status);
        return ResponseEntity.ok(progressItems);
    }

    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @Operation(
            summary = "根据时间范围获取进度记录",
            description = "获取指定时间范围内的进度记录列表，USER 和 ADMIN 角色均可访问。时间格式为 yyyy-MM-dd'T'HH:mm:ss。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回进度记录列表"),
            @ApiResponse(responseCode = "400", description = "无效的时间范围参数"),
            @ApiResponse(responseCode = "403", description = "无权限访问，需 USER 或 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<ProgressItem>> getProgressByTimeRange(
            @RequestParam @Parameter(description = "开始时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true, example = "2023-01-01T00:00:00") LocalDateTime startTime,
            @RequestParam @Parameter(description = "结束时间，格式：yyyy-MM-dd'T'HH:mm:ss", required = true, example = "2023-12-31T23:59:59") LocalDateTime endTime) {
        List<ProgressItem> progressItems = progressItemService.getProgressByTimeRange(startTime, endTime);
        return ResponseEntity.ok(progressItems);
    }

    private boolean isValidStatus(String status) {
        return "PENDING".equalsIgnoreCase(status) || "PROCESSING".equalsIgnoreCase(status) ||
                "COMPLETED".equalsIgnoreCase(status) || "ARCHIVED".equalsIgnoreCase(status);
    }
}