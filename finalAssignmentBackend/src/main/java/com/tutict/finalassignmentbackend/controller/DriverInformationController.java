package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/eventbus/drivers")
public class DriverInformationController {

    private final DriverInformationService driverInformationService;

    @Autowired
    public DriverInformationController(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    @PostMapping
    public ResponseEntity<Void> createDriver(@RequestBody DriverInformation driverInformation) {
        driverInformationService.createDriver(driverInformation);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{driverId}")
    public ResponseEntity<DriverInformation> getDriverById(@PathVariable int driverId) {
        DriverInformation driverInformation = driverInformationService.getDriverById(driverId);
        if (driverInformation != null) {
            return ResponseEntity.ok(driverInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<DriverInformation>> getAllDrivers() {
        List<DriverInformation> drivers = driverInformationService.getAllDrivers();
        return ResponseEntity.ok(drivers);
    }

    @PutMapping("/{driverId}")
    public ResponseEntity<Void> updateDriver(@PathVariable int driverId, @RequestBody DriverInformation updatedDriverInformation) {
        DriverInformation existingDriverInformation = driverInformationService.getDriverById(driverId);
        if (existingDriverInformation != null) {
            updatedDriverInformation.setDriverId(driverId);
            driverInformationService.updateDriver(updatedDriverInformation);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{driverId}")
    public ResponseEntity<Void> deleteDriver(@PathVariable int driverId) {
        driverInformationService.deleteDriver(driverId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/idCardNumber/{idCardNumber}")
    public ResponseEntity<List<DriverInformation>> getDriversByIdCardNumber(@PathVariable String idCardNumber) {
        List<DriverInformation> drivers = driverInformationService.getDriversByIdCardNumber(idCardNumber);
        return ResponseEntity.ok(drivers);
    }

    @GetMapping("/driverLicenseNumber/{driverLicenseNumber}")
    public ResponseEntity<DriverInformation> getDriverByDriverLicenseNumber(@PathVariable String driverLicenseNumber) {
        DriverInformation driverInformation = driverInformationService.getDriverByDriverLicenseNumber(driverLicenseNumber);
        if (driverInformation != null) {
            return ResponseEntity.ok(driverInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/name/{name}")
    public ResponseEntity<List<DriverInformation>> getDriversByName(@PathVariable String name) {
        List<DriverInformation> drivers = driverInformationService.getDriversByName(name);
        return ResponseEntity.ok(drivers);
    }
}