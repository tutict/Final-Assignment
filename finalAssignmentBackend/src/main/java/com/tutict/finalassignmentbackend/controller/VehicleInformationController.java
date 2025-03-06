package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/vehicles")
public class VehicleInformationController {

    private final VehicleInformationService vehicleInformationService;

    public VehicleInformationController(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    @PostMapping
    @Transactional
    @PreAuthorize("hasRole('ADMIN', 'USER')")
    public ResponseEntity<Void> createVehicleInformation(@RequestBody VehicleInformation vehicleInformation, @RequestParam String idempotencyKey) {
        vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, vehicleInformation, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{vehicleId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<VehicleInformation> getVehicleInformationById(@PathVariable int vehicleId) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationById(vehicleId);
        if (vehicleInformation != null) {
            return ResponseEntity.ok(vehicleInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/license-plate/{licensePlate}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<VehicleInformation> getVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
        if (vehicleInformation != null) {
            return ResponseEntity.ok(vehicleInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getAllVehicleInformation() {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getAllVehicleInformation();
        return ResponseEntity.ok(vehicleInformationList);
    }

    @GetMapping("/type/{vehicleType}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByType(@PathVariable String vehicleType) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByType(vehicleType);
        return ResponseEntity.ok(vehicleInformationList);
    }

    @GetMapping("/owner/{ownerName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByOwnerName(@PathVariable String ownerName) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByOwnerName(ownerName);
        return ResponseEntity.ok(vehicleInformationList);
    }

    @GetMapping("/status/{currentStatus}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByStatus(@PathVariable String currentStatus) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByStatus(currentStatus);
        return ResponseEntity.ok(vehicleInformationList);
    }

    @PutMapping("/{vehicleId}")
    @Transactional
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<VehicleInformation> updateVehicleInformation(@PathVariable int vehicleId, @RequestBody VehicleInformation vehicleInformation, @RequestParam String idempotencyKey) {
        vehicleInformation.setVehicleId(vehicleId);
        vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, vehicleInformation, "update");
        return ResponseEntity.ok(vehicleInformation);
    }

    @DeleteMapping("/{vehicleId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Void> deleteVehicleInformation(@PathVariable int vehicleId) {
        vehicleInformationService.deleteVehicleInformation(vehicleId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/license-plate/{licensePlate}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Void> deleteVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/exists/{licensePlate}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Boolean> isLicensePlateExists(@PathVariable String licensePlate) {
        boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
        return ResponseEntity.ok(exists);
    }
}