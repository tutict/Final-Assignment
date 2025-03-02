package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
@RequestMapping("/api/vehicles")
public class VehicleInformationController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final VehicleInformationService vehicleInformationService;

    public VehicleInformationController(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    @PostMapping
    @Transactional
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> createVehicleInformation(@RequestBody VehicleInformation vehicleInformation, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, vehicleInformation, "create");
            return ResponseEntity.status(201).build();
        }, virtualThreadExecutor);
    }

    @GetMapping("/{vehicleId}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<VehicleInformation>> getVehicleInformationById(@PathVariable int vehicleId) {
        return CompletableFuture.supplyAsync(() -> {
            VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationById(vehicleId);
            if (vehicleInformation != null) {
                return ResponseEntity.ok(vehicleInformation);
            } else {
                return ResponseEntity.status(404).build();
            }
        }, virtualThreadExecutor);
    }

    @GetMapping("/license-plate/{licensePlate}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<VehicleInformation>> getVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        return CompletableFuture.supplyAsync(() -> {
            VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
            if (vehicleInformation != null) {
                return ResponseEntity.ok(vehicleInformation);
            } else {
                return ResponseEntity.status(404).build();
            }
        }, virtualThreadExecutor);
    }

    @GetMapping
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<VehicleInformation>>> getAllVehicleInformation() {
        return CompletableFuture.supplyAsync(() -> {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getAllVehicleInformation();
            return ResponseEntity.ok(vehicleInformationList);
        }, virtualThreadExecutor);
    }

    @GetMapping("/type/{vehicleType}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<VehicleInformation>>> getVehicleInformationByType(@PathVariable String vehicleType) {
        return CompletableFuture.supplyAsync(() -> {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByType(vehicleType);
            return ResponseEntity.ok(vehicleInformationList);
        }, virtualThreadExecutor);
    }

    @GetMapping("/owner/{ownerName}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<VehicleInformation>>> getVehicleInformationByOwnerName(@PathVariable String ownerName) {
        return CompletableFuture.supplyAsync(() -> {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByOwnerName(ownerName);
            return ResponseEntity.ok(vehicleInformationList);
        }, virtualThreadExecutor);
    }

    @GetMapping("/status/{currentStatus}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<VehicleInformation>>> getVehicleInformationByStatus(@PathVariable String currentStatus) {
        return CompletableFuture.supplyAsync(() -> {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByStatus(currentStatus);
            return ResponseEntity.ok(vehicleInformationList);
        }, virtualThreadExecutor);
    }

    @PutMapping("/{vehicleId}")
    @Transactional
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<VehicleInformation>> updateVehicleInformation(@PathVariable int vehicleId, @RequestBody VehicleInformation vehicleInformation, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            vehicleInformation.setVehicleId(vehicleId);
            vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, vehicleInformation, "update");
            return ResponseEntity.ok(vehicleInformation);
        }, virtualThreadExecutor);
    }

    @DeleteMapping("/{vehicleId}")
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> deleteVehicleInformation(@PathVariable int vehicleId) {
        return CompletableFuture.supplyAsync(() -> {
            vehicleInformationService.deleteVehicleInformation(vehicleId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    @DeleteMapping("/license-plate/{licensePlate}")
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> deleteVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        return CompletableFuture.supplyAsync(() -> {
            vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    @GetMapping("/exists/{licensePlate}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<Boolean>> isLicensePlateExists(@PathVariable String licensePlate) {
        return CompletableFuture.supplyAsync(() -> {
            boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
            return ResponseEntity.ok(exists);
        }, virtualThreadExecutor);
    }
}