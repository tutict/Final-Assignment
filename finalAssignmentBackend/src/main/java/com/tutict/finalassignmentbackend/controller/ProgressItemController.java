package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.ProgressItem;
import com.tutict.finalassignmentbackend.service.ProgressItemService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.time.LocalDateTime;
import java.util.List;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/progress")
public class ProgressItemController {

    private static final Logger logger = Logger.getLogger(ProgressItemController.class.getName());

    private final ProgressItemService progressItemService;

    public ProgressItemController(ProgressItemService progressItemService) {
        this.progressItemService = progressItemService;
    }

    // 创建新的进度记录（仅 USER）
    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<ProgressItem> createProgress(@RequestBody ProgressItem progressItem) {
        logger.info("Attempting to create progress item with title: " + progressItem.getTitle());
        ProgressItem savedItem = progressItemService.createProgress(progressItem);
        logger.info("Progress item created successfully with ID: " + savedItem.getId());
        return new ResponseEntity<>(savedItem, HttpStatus.CREATED);
    }

    // 管理员查看所有进度记录
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<ProgressItem>> getAllProgress() {
        List<ProgressItem> progressItems = progressItemService.getAllProgress();
        return ResponseEntity.ok(progressItems);
    }

    // 用户查看自己的进度记录（按用户名）
    @GetMapping(params = "username")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<List<ProgressItem>> getProgressByUsername(@RequestParam String username) {
        List<ProgressItem> progressItems = progressItemService.getProgressByUsername(username);
        return ResponseEntity.ok(progressItems);
    }

    // 更新进度状态（仅 ADMIN）
    @PutMapping("/{progressId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ProgressItem> updateProgressStatus(
            @PathVariable int progressId, @RequestBody ProgressItem updatedProgressItem) {
        ProgressItem updatedItem = progressItemService.updateProgressStatus(progressId, updatedProgressItem);
        if (updatedItem != null) {
            logger.info("Progress item with ID " + progressId + " updated successfully.");
            return ResponseEntity.ok(updatedItem);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除进度记录（仅 ADMIN）
    @DeleteMapping("/{progressId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteProgress(@PathVariable int progressId) {
        progressItemService.deleteProgress(progressId);
        logger.info("Progress item with ID " + progressId + " deleted successfully.");
        return ResponseEntity.noContent().build();
    }

    // 根据状态获取进度记录（USER 和 ADMIN）
    @GetMapping("/status/{status}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<ProgressItem>> getProgressByStatus(@PathVariable String status) {
        // 验证状态有效性
        if (!isValidStatus(status)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        List<ProgressItem> progressItems = progressItemService.getProgressByStatus(status);
        return ResponseEntity.ok(progressItems);
    }

    // 根据提交时间范围获取进度记录（USER 和 ADMIN）
    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<ProgressItem>> getProgressByTimeRange(
            @RequestParam LocalDateTime startTime, @RequestParam LocalDateTime endTime) {
        List<ProgressItem> progressItems = progressItemService.getProgressByTimeRange(startTime, endTime);
        return ResponseEntity.ok(progressItems);
    }

    // 验证状态的有效性
    private boolean isValidStatus(String status) {
        return "Pending".equals(status) || "Processing".equals(status) ||
                "Completed".equals(status) || "Archived".equals(status);
    }
}