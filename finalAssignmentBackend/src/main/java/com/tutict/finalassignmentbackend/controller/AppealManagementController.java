package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/appeals")
public class AppealManagementController {

    private static final Logger logger = Logger.getLogger(AppealManagementController.class.getName());

    // Creating virtual thread pool
    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final AppealManagementService appealManagementService;

    public AppealManagementController(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    // Create a new appeal
    @PostMapping
    @Async
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

    // Get appeal by ID
    @GetMapping("/{appealId}")
    @Async
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

    // Get all appeals
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAllAppeals() {
        return CompletableFuture.supplyAsync(() -> {
            List<AppealManagement> appeals = appealManagementService.getAllAppeals();
            return ResponseEntity.ok(appeals);
        }, virtualThreadExecutor);
    }

    // Update appeal information
    @PutMapping("/{appealId}")
    @Async
    @Transactional
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

    // Delete appeal
    @DeleteMapping("/{appealId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteAppeal(@PathVariable Integer appealId) {
        return CompletableFuture.supplyAsync(() -> {
            appealManagementService.deleteAppeal(appealId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // Get appeals by process status
    @GetMapping("/status/{processStatus}")
    @Async
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAppealsByProcessStatus(@PathVariable String processStatus) {
        return CompletableFuture.supplyAsync(() -> {
            List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
            return ResponseEntity.ok(appeals);
        }, virtualThreadExecutor);
    }

    // Get appeals by appellant name
    @GetMapping("/name/{appealName}")
    @Async
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAppealsByAppealName(@PathVariable String appealName) {
        return CompletableFuture.supplyAsync(() -> {
            List<AppealManagement> appeals = appealManagementService.getAppealsByAppealName(appealName);
            return ResponseEntity.ok(appeals);
        }, virtualThreadExecutor);
    }

    // Get offense information by appeal ID
    @GetMapping("/{appealId}/offense")
    @Async
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
