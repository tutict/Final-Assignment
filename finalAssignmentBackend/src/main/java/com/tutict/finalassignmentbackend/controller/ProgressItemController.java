package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.ProgressItem;
import com.tutict.finalassignmentbackend.service.ProgressItemService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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

    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<ProgressItem> createProgress(@RequestBody ProgressItem progressItem) {
        logger.info("Attempting to create progress item with title: " + progressItem.getTitle());
        ProgressItem savedItem = progressItemService.createProgress(progressItem);
        logger.info("Progress item created successfully with ID: " + savedItem.getId());
        return new ResponseEntity<>(savedItem, HttpStatus.CREATED);
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<ProgressItem>> getAllProgress() {
        List<ProgressItem> progressItems = progressItemService.getAllProgress();
        return ResponseEntity.ok(progressItems);
    }

    @GetMapping(params = "username")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<List<ProgressItem>> getProgressByUsername(@RequestParam String username) {
        List<ProgressItem> progressItems = progressItemService.getProgressByUsername(username);
        return ResponseEntity.ok(progressItems);
    }

    @PutMapping("/{progressId}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ProgressItem> updateProgressStatus(
            @PathVariable int progressId, @RequestParam String newStatus) {
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
    public ResponseEntity<Void> deleteProgress(@PathVariable int progressId) {
        progressItemService.deleteProgress(progressId);
        logger.info("Progress item with ID " + progressId + " deleted successfully.");
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<ProgressItem>> getProgressByStatus(@PathVariable String status) {
        if (!isValidStatus(status)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        List<ProgressItem> progressItems = progressItemService.getProgressByStatus(status);
        return ResponseEntity.ok(progressItems);
    }

    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<ProgressItem>> getProgressByTimeRange(
            @RequestParam LocalDateTime startTime, @RequestParam LocalDateTime endTime) {
        List<ProgressItem> progressItems = progressItemService.getProgressByTimeRange(startTime, endTime);
        return ResponseEntity.ok(progressItems);
    }

    private boolean isValidStatus(String status) {
        return "PENDING".equalsIgnoreCase(status) || "PROCESSING".equalsIgnoreCase(status) ||
                "COMPLETED".equalsIgnoreCase(status) || "ARCHIVED".equalsIgnoreCase(status);
    }
}