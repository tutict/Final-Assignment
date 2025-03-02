package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/appeals")
public class AppealManagementController {

    private static final Logger logger = Logger.getLogger(AppealManagementController.class.getName());

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final AppealManagementService appealManagementService;

    public AppealManagementController(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    // Create a new appeal (仅 ADMIN)
    @PostMapping
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> createAppeal(@RequestBody AppealManagement appeal, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                appealManagementService.checkAndInsertIdempotency(idempotencyKey, appeal, "create");
                return ResponseEntity.status(HttpStatus.CREATED).build();
            } catch (Exception e) {
                logger.warning("Error creating appeal: " + e.getMessage());
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
            }
        }, virtualThreadExecutor);
    }

    // Get appeal by ID (USER 和 ADMIN)
    @GetMapping("/{appealId}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<AppealManagement>> getAppealById(@PathVariable Integer appealId) {
        return CompletableFuture.supplyAsync(() -> {
            AppealManagement appeal = appealManagementService.getAppealById(appealId);
            if (appeal != null) {
                return ResponseEntity.ok(appeal);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // Get all appeals (USER 和 ADMIN)
    @GetMapping
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAllAppeals() {
        return CompletableFuture.supplyAsync(() -> {
            List<AppealManagement> appeals = appealManagementService.getAllAppeals();
            return ResponseEntity.ok(appeals);
        }, virtualThreadExecutor);
    }

    // Update appeal information (仅 ADMIN)
    @PutMapping("/{appealId}")
    @Async
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> updateAppeal(@PathVariable Integer appealId, @RequestBody AppealManagement updatedAppeal, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            AppealManagement existingAppeal = appealManagementService.getAppealById(appealId);
            if (existingAppeal != null) {
                existingAppeal.setOffenseId(updatedAppeal.getOffenseId());
                existingAppeal.setAppellantName(updatedAppeal.getAppellantName());
                existingAppeal.setIdCardNumber(updatedAppeal.getIdCardNumber());
                existingAppeal.setContactNumber(updatedAppeal.getContactNumber());
                existingAppeal.setAppealReason(updatedAppeal.getAppealReason());
                existingAppeal.setAppealTime(updatedAppeal.getAppealTime());
                existingAppeal.setProcessStatus(updatedAppeal.getProcessStatus());
                existingAppeal.setProcessResult(updatedAppeal.getProcessResult());

                appealManagementService.checkAndInsertIdempotency(idempotencyKey, existingAppeal, "update");
                return ResponseEntity.ok().build();
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // Delete appeal (仅 ADMIN)
    @DeleteMapping("/{appealId}")
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> deleteAppeal(@PathVariable Integer appealId) {
        return CompletableFuture.supplyAsync(() -> {
            appealManagementService.deleteAppeal(appealId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // Get appeals by process status (USER 和 ADMIN)
    @GetMapping("/status/{processStatus}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAppealsByProcessStatus(@PathVariable String processStatus) {
        return CompletableFuture.supplyAsync(() -> {
            List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
            return ResponseEntity.ok(appeals);
        }, virtualThreadExecutor);
    }

    // Get appeals by appellant name (USER 和 ADMIN)
    @GetMapping("/name/{appealName}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAppealsByAppealName(@PathVariable String appealName) {
        return CompletableFuture.supplyAsync(() -> {
            List<AppealManagement> appeals = appealManagementService.getAppealsByAppealName(appealName);
            return ResponseEntity.ok(appeals);
        }, virtualThreadExecutor);
    }

    // Get offense information by appeal ID (USER 和 ADMIN)
    @GetMapping("/{appealId}/offense")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<OffenseInformation>> getOffenseByAppealId(@PathVariable Integer appealId) {
        return CompletableFuture.supplyAsync(() -> {
            OffenseInformation offense = appealManagementService.getOffenseByAppealId(appealId);
            if (offense != null) {
                return ResponseEntity.ok(offense);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }
}