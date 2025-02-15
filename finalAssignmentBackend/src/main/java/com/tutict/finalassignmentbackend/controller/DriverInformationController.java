package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
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

@RestController
@RequestMapping("/api/drivers")
public class DriverInformationController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final DriverInformationService driverInformationService;

    public DriverInformationController(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    // 创建司机信息
    @PostMapping
    @Async
    public CompletableFuture<ResponseEntity<Void>> createDriver(@RequestBody DriverInformation driverInformation, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            driverInformationService.checkAndInsertIdempotency(idempotencyKey, driverInformation, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据司机ID获取司机信息
    @GetMapping("/{driverId}")
    @Async
    public CompletableFuture<ResponseEntity<DriverInformation>> getDriverById(@PathVariable int driverId) {
        return CompletableFuture.supplyAsync(() -> {
            DriverInformation driverInformation = driverInformationService.getDriverById(driverId);
            if (driverInformation != null) {
                return ResponseEntity.ok(driverInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有司机信息
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<DriverInformation>>> getAllDrivers() {
        return CompletableFuture.supplyAsync(() -> {
            List<DriverInformation> drivers = driverInformationService.getAllDrivers();
            return ResponseEntity.ok(drivers);
        }, virtualThreadExecutor);
    }

    // 更新司机信息
    @PutMapping("/{driverId}")
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<DriverInformation>> updateDriver(@PathVariable int driverId, @RequestBody DriverInformation updatedDriverInformation, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            DriverInformation existingDriverInformation = driverInformationService.getDriverById(driverId);
            if (existingDriverInformation != null) {
                updatedDriverInformation.setDriverId(driverId);
                driverInformationService.checkAndInsertIdempotency(idempotencyKey, updatedDriverInformation, "update");
                return ResponseEntity.ok(updatedDriverInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除指定ID的司机信息
    @DeleteMapping("/{driverId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteDriver(@PathVariable int driverId) {
        return CompletableFuture.supplyAsync(() -> {
            driverInformationService.deleteDriver(driverId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据身份证号获取司机信息
    @GetMapping("/idCardNumber/{idCardNumber}")
    @Async
    public CompletableFuture<ResponseEntity<List<DriverInformation>>> getDriversByIdCardNumber(@PathVariable String idCardNumber) {
        return CompletableFuture.supplyAsync(() -> {
            List<DriverInformation> drivers = driverInformationService.getDriversByIdCardNumber(idCardNumber);
            return ResponseEntity.ok(drivers);
        }, virtualThreadExecutor);
    }

    // 根据驾驶证号获取司机信息
    @GetMapping("/driverLicenseNumber/{driverLicenseNumber}")
    @Async
    public CompletableFuture<ResponseEntity<DriverInformation>> getDriverByDriverLicenseNumber(@PathVariable String driverLicenseNumber) {
        return CompletableFuture.supplyAsync(() -> {
            DriverInformation driverInformation = driverInformationService.getDriverByDriverLicenseNumber(driverLicenseNumber);
            if (driverInformation != null) {
                return ResponseEntity.ok(driverInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 根据司机姓名获取司机信息
    @GetMapping("/name/{name}")
    @Async
    public CompletableFuture<ResponseEntity<List<DriverInformation>>> getDriversByName(@PathVariable String name) {
        return CompletableFuture.supplyAsync(() -> {
            List<DriverInformation> drivers = driverInformationService.getDriversByName(name);
            return ResponseEntity.ok(drivers);
        }, virtualThreadExecutor);
    }
}
