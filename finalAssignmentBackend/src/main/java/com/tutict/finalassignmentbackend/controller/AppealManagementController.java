package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
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
public class AppealManagementController {

    private static final Logger logger = Logger.getLogger(AppealManagementController.class.getName());

    private final AppealManagementService appealManagementService;

    public AppealManagementController(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    // Create a new appeal (USER permission)
    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<AppealManagement> createAppeal(
            @RequestBody AppealManagement appeal,
            @RequestParam String idempotencyKey) {
        try {
            appealManagementService.checkAndInsertIdempotency(idempotencyKey, appeal, "create");
            AppealManagement createdAppeal = appealManagementService.createAppeal(appeal);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdAppeal);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid input for creating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
        } catch (RuntimeException e) {
            logger.severe("Error creating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    // Get appeal by ID (USER and ADMIN)
    @GetMapping("/{appealId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<AppealManagement> getAppealById(@PathVariable Integer appealId) {
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

    // Get all appeals (USER and ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAllAppeals() {
        List<AppealManagement> appeals = appealManagementService.getAllAppeals();
        return ResponseEntity.ok(appeals);
    }

    // Update appeal information (ADMIN only)
    @PutMapping("/{appealId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AppealManagement> updateAppeal(
            @PathVariable Integer appealId,
            @RequestBody AppealManagement updatedAppeal,
            @RequestParam String idempotencyKey) {
        try {
            AppealManagement existingAppeal = appealManagementService.getAppealById(appealId);
            if (existingAppeal == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            updatedAppeal.setAppealId(appealId); // Ensure ID consistency
            appealManagementService.checkAndInsertIdempotency(idempotencyKey, updatedAppeal, "update");
            AppealManagement updated = appealManagementService.updateAppeal(updatedAppeal);
            return ResponseEntity.ok(updated);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid input for updating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (RuntimeException e) {
            logger.severe("Error updating appeal: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // Delete appeal (ADMIN only)
    @DeleteMapping("/{appealId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteAppeal(@PathVariable Integer appealId) {
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

    // Get appeals by process status (USER and ADMIN)
    @GetMapping("/status/{processStatus}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByProcessStatus(@PathVariable String processStatus) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid process status: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // Get appeals by appellant name (USER and ADMIN)
    @GetMapping("/name/{appellantName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByAppellantName(@PathVariable String appellantName) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByAppellantName(appellantName);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid appellant name: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // Get offense information by appeal ID (USER and ADMIN)
    @GetMapping("/{appealId}/offense")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<OffenseInformation> getOffenseByAppealId(@PathVariable Integer appealId) {
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

    // Get appeals by ID card number (USER and ADMIN)
    @GetMapping("/id-card/{idCardNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByIdCardNumber(@PathVariable String idCardNumber) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByIdCardNumber(idCardNumber);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid ID card number: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // Get appeals by contact number (USER and ADMIN)
    @GetMapping("/contact/{contactNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByContactNumber(@PathVariable String contactNumber) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByContactNumber(contactNumber);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid contact number: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // Get appeals by offense ID (USER and ADMIN)
    @GetMapping("/offense/{offenseId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByOffenseId(@PathVariable Integer offenseId) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByOffenseId(offenseId);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid offense ID: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // Get appeals by appeal time range (USER and ADMIN)
    @GetMapping("/time-range")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByAppealTimeBetween(
            @RequestParam String startTime,
            @RequestParam String endTime) {
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
    public ResponseEntity<List<AppealManagement>> searchByAppellantName(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

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
    public ResponseEntity<List<AppealManagement>> searchByAppealReason(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

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

    // Count appeals by process status (USER and ADMIN)
    @GetMapping("/count/status/{processStatus}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Long> countAppealsByStatus(@PathVariable String processStatus) {
        try {
            long count = appealManagementService.countAppealsByStatus(processStatus);
            return ResponseEntity.ok(count);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid process status: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // New endpoint: Get appeals by appeal reason containing (USER and ADMIN)
    @GetMapping("/reason/{reason}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByReasonContaining(@PathVariable String reason) {
        try {
            List<AppealManagement> appeals = appealManagementService.getAppealsByReasonContaining(reason);
            return ResponseEntity.ok(appeals);
        } catch (IllegalArgumentException e) {
            logger.warning("Invalid appeal reason: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // New endpoint: Get appeals by process status and time range (USER and ADMIN)
    @GetMapping("/status-and-time")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<AppealManagement>> getAppealsByStatusAndTime(
            @RequestParam String processStatus,
            @RequestParam String startTime,
            @RequestParam String endTime) {
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