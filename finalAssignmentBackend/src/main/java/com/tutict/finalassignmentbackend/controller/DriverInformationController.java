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

@RestController
@RequestMapping("/api/drivers")
public class DriverInformationController {

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

    // 根据身份证号获取司机信息 (ADMIN 和 USER)
    @GetMapping("/idCardNumber/{idCardNumber}")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<List<DriverInformation>> getDriversByIdCardNumber(@PathVariable String idCardNumber) {
        try {
            List<DriverInformation> drivers = driverInformationService.getDriversByIdCardNumber(idCardNumber);
            return ResponseEntity.ok(drivers);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // 根据驾驶证号获取司机信息 (ADMIN 和 USER)
    @GetMapping("/driverLicenseNumber/{driverLicenseNumber}")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<DriverInformation> getDriverByDriverLicenseNumber(@PathVariable String driverLicenseNumber) {
        try {
            DriverInformation driverInformation = driverInformationService.getDriverByDriverLicenseNumber(driverLicenseNumber);
            if (driverInformation != null) {
                return ResponseEntity.ok(driverInformation);
            }
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // 根据司机姓名获取司机信息 (ADMIN 和 USER)
    @GetMapping("/name/{name}")
    @PreAuthorize("hasAnyRole('ROLE_ADMIN', 'ROLE_USER')")
    public ResponseEntity<List<DriverInformation>> getDriversByName(@PathVariable String name) {
        try {
            List<DriverInformation> drivers = driverInformationService.getDriversByName(name);
            return ResponseEntity.ok(drivers);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // Helper method to update UserManagement.modifiedTime
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