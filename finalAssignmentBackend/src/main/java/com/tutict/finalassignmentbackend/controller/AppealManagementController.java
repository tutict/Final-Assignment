package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/appeals")
public class AppealManagementController {

    private static final Logger logger = Logger.getLogger(AppealManagementController.class.getName());

    private final AppealManagementService appealManagementService;

    public AppealManagementController(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    // Create a new appeal (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createAppeal(@RequestBody AppealManagement appeal, @RequestParam String idempotencyKey) {
        try {
            appealManagementService.checkAndInsertIdempotency(idempotencyKey, appeal, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (Exception e) {
            logger.warning("Error creating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // Get appeal by ID (USER 和 ADMIN)
    @GetMapping("/{appealId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<AppealManagement> getAppealById(@PathVariable Integer appealId) {
        AppealManagement appeal = appealManagementService.getAppealById(appealId);
        if (appeal != null) {
            return ResponseEntity.ok(appeal);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // Get all appeals (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAllAppeals() {
        List<AppealManagement> appeals = appealManagementService.getAllAppeals();
        return ResponseEntity.ok(appeals);
    }

    // Update appeal information (仅 ADMIN)
    @PutMapping("/{appealId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> updateAppeal(@PathVariable Integer appealId, @RequestBody AppealManagement updatedAppeal, @RequestParam String idempotencyKey) {
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
    }

    // Delete appeal (仅 ADMIN)
    @DeleteMapping("/{appealId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteAppeal(@PathVariable Integer appealId) {
        appealManagementService.deleteAppeal(appealId);
        return ResponseEntity.noContent().build();
    }

    // Get appeals by process status (USER 和 ADMIN)
    @GetMapping("/status/{processStatus}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByProcessStatus(@PathVariable String processStatus) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
        return ResponseEntity.ok(appeals);
    }

    // Get appeals by appellant name (USER 和 ADMIN)
    @GetMapping("/name/{appealName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByAppealName(@PathVariable String appealName) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByAppealName(appealName);
        return ResponseEntity.ok(appeals);
    }

    // Get offense information by appeal ID (USER 和 ADMIN)
    @GetMapping("/{appealId}/offense")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<OffenseInformation> getOffenseByAppealId(@PathVariable Integer appealId) {
        OffenseInformation offense = appealManagementService.getOffenseByAppealId(appealId);
        if (offense != null) {
            return ResponseEntity.ok(offense);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
}