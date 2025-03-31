package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import com.tutict.finalassignmentbackend.service.UserManagementService; // Add this
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Level;

@RestController
@RequestMapping("/api/drivers")
public class DriverInformationController {

    private static final Logger logger = Logger.getLogger(DriverInformationController.class.getName());

    private final DriverInformationService driverInformationService;
    private final UserManagementService userManagementService; // Add this

    public DriverInformationController(
            DriverInformationService driverInformationService,
            UserManagementService userManagementService) { // Inject UserManagementService
        this.driverInformationService = driverInformationService;
        this.userManagementService = userManagementService;
    }

    // 创建司机信息 (ADMIN 和 USER)
    @PostMapping
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<Void> createDriver(
            @RequestBody DriverInformation driverInformation,
            @RequestParam String idempotencyKey) {
        try {
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, driverInformation, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // 根据司机ID获取司机信息 (ADMIN 和 USER)
    @GetMapping("/{driverId}")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<DriverInformation> getDriverById(@PathVariable int driverId) {
        try {
            DriverInformation driverInformation = driverInformationService.getDriverById(driverId);
            if (driverInformation != null) {
                return ResponseEntity.ok(driverInformation);
            }
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // 获取所有司机信息 (ADMIN 和 USER)
    @GetMapping
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<List<DriverInformation>> getAllDrivers() {
        List<DriverInformation> drivers = driverInformationService.getAllDrivers();
        return ResponseEntity.ok(drivers);
    }

    // 更新司机姓名 (ADMIN 和 USER)
    @PutMapping("/{driverId}/name")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<Void> updateDriverName(
            @PathVariable int driverId,
            @RequestBody String name,
            @RequestParam String idempotencyKey) {
        try {
            DriverInformation existingDriver = driverInformationService.getDriverById(driverId);
            if (existingDriver == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            existingDriver.setName(name);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, existingDriver, "update");
            updateUserManagementModifiedTime(driverId); // Update UserManagement
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // 更新司机联系电话 (ADMIN 和 USER)
    @PutMapping("/{driverId}/contactNumber")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<Void> updateDriverContactNumber(
            @PathVariable int driverId,
            @RequestBody String contactNumber,
            @RequestParam String idempotencyKey) {
        try {
            DriverInformation existingDriver = driverInformationService.getDriverById(driverId);
            if (existingDriver == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            existingDriver.setContactNumber(contactNumber);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, existingDriver, "update");
            updateUserManagementModifiedTime(driverId); // Update UserManagement
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // 更新司机身份证号码 (ADMIN 和 USER)
    @PutMapping("/{driverId}/idCardNumber")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<Void> updateDriverIdCardNumber(
            @PathVariable int driverId,
            @RequestBody String idCardNumber,
            @RequestParam String idempotencyKey) {
        try {
            DriverInformation existingDriver = driverInformationService.getDriverById(driverId);
            if (existingDriver == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            existingDriver.setIdCardNumber(idCardNumber);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, existingDriver, "update");
            updateUserManagementModifiedTime(driverId); // Update UserManagement
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // 更新司机完整信息 (ADMIN 和 USER)
    @PutMapping("/{driverId}")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<Void> updateDriver(
            @PathVariable int driverId,
            @RequestBody DriverInformation updatedDriverInformation,
            @RequestParam String idempotencyKey) {
        try {
            DriverInformation existingDriver = driverInformationService.getDriverById(driverId);
            if (existingDriver == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            updatedDriverInformation.setDriverId(driverId);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, updatedDriverInformation, "update");
            updateUserManagementModifiedTime(driverId); // Update UserManagement
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // 删除指定ID的司机信息 (仅 ADMIN)
    @DeleteMapping("/{driverId}")
    @PreAuthorize("hasRole('ROLE_ADMIN')")
    public ResponseEntity<Void> deleteDriver(@PathVariable int driverId) {
        try {
            driverInformationService.deleteDriver(driverId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/by-id-card")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<List<DriverInformation>> searchByIdCardNumber(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        logger.log(Level.INFO, "Received request to search drivers by ID card number: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        try {
            List<DriverInformation> results = driverInformationService.searchByIdCardNumber(query, page, size);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No drivers found for ID card number: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} drivers for ID card number: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for ID card search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by ID card number: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    // 根据驾驶证号获取司机信息 (ADMIN 和 USER)
    @GetMapping("/by-license-number")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<List<DriverInformation>> searchByDriverLicenseNumber(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        logger.log(Level.INFO, "Received request to search drivers by driver license number: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        try {
            List<DriverInformation> results = driverInformationService.searchByDriverLicenseNumber(query, page, size);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No drivers found for driver license number: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} drivers for driver license number: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for license number search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by driver license number: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    // 根据司机姓名获取司机信息 (ADMIN 和 USER)
    @GetMapping("/by-name")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<List<DriverInformation>> searchByName(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        logger.log(Level.INFO, "Received request to search drivers by name: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        try {
            List<DriverInformation> results = driverInformationService.searchByName(query, page, size);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No drivers found for name: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} drivers for name: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for name search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by name: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    private void updateUserManagementModifiedTime(int driverId) {
        UserManagement user = userManagementService.getUserById(driverId); // Assuming driverId matches userId
        if (user != null) {
            user.setModifiedTime(LocalDateTime.now());
            userManagementService.updateUser(user);
        } else {
            System.out.println("No UserManagement found for driverId: " + driverId);
        }
    }
}