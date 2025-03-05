package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/drivers")
public class DriverInformationController {

    private final DriverInformationService driverInformationService;

    public DriverInformationController(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    // 创建司机信息 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createDriver(@RequestBody DriverInformation driverInformation, @RequestParam String idempotencyKey) {
        driverInformationService.checkAndInsertIdempotency(idempotencyKey, driverInformation, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据司机ID获取司机信息 (USER 和 ADMIN)
    @GetMapping("/{driverId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<DriverInformation> getDriverById(@PathVariable int driverId) {
        DriverInformation driverInformation = driverInformationService.getDriverById(driverId);
        if (driverInformation != null) {
            return ResponseEntity.ok(driverInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有司机信息 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<DriverInformation>> getAllDrivers() {
        List<DriverInformation> drivers = driverInformationService.getAllDrivers();
        return ResponseEntity.ok(drivers);
    }

    // 更新司机信息 (仅 ADMIN)
    @PutMapping("/{driverId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<DriverInformation> updateDriver(@PathVariable int driverId, @RequestBody DriverInformation updatedDriverInformation, @RequestParam String idempotencyKey) {
        DriverInformation existingDriverInformation = driverInformationService.getDriverById(driverId);
        if (existingDriverInformation != null) {
            updatedDriverInformation.setDriverId(driverId);
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, updatedDriverInformation, "update");
            return ResponseEntity.ok(updatedDriverInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除指定ID的司机信息 (仅 ADMIN)
    @DeleteMapping("/{driverId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteDriver(@PathVariable int driverId) {
        driverInformationService.deleteDriver(driverId);
        return ResponseEntity.noContent().build();
    }

    // 根据身份证号获取司机信息 (USER 和 ADMIN)
    @GetMapping("/idCardNumber/{idCardNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<DriverInformation>> getDriversByIdCardNumber(@PathVariable String idCardNumber) {
        List<DriverInformation> drivers = driverInformationService.getDriversByIdCardNumber(idCardNumber);
        return ResponseEntity.ok(drivers);
    }

    // 根据驾驶证号获取司机信息 (USER 和 ADMIN)
    @GetMapping("/driverLicenseNumber/{driverLicenseNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<DriverInformation> getDriverByDriverLicenseNumber(@PathVariable String driverLicenseNumber) {
        DriverInformation driverInformation = driverInformationService.getDriverByDriverLicenseNumber(driverLicenseNumber);
        if (driverInformation != null) {
            return ResponseEntity.ok(driverInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 根据司机姓名获取司机信息 (USER 和 ADMIN)
    @GetMapping("/name/{name}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<DriverInformation>> getDriversByName(@PathVariable String name) {
        List<DriverInformation> drivers = driverInformationService.getDriversByName(name);
        return ResponseEntity.ok(drivers);
    }
}