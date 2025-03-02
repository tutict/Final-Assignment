package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.scheduling.annotation.Async;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
@RequestMapping("/api/offenses")
public class OffenseInformationController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final OffenseInformationService offenseInformationService;

    public OffenseInformationController(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    // 创建新的违法行为信息 (仅 ADMIN)
    @PostMapping
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> createOffense(@RequestBody OffenseInformation offenseInformation, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            offenseInformationService.checkAndInsertIdempotency(idempotencyKey, offenseInformation, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据违法行为ID获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/{offenseId}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<OffenseInformation>> getOffenseByOffenseId(@PathVariable int offenseId) {
        return CompletableFuture.supplyAsync(() -> {
            OffenseInformation offenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
            if (offenseInformation != null) {
                return ResponseEntity.ok(offenseInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有违法行为的信息 (USER 和 ADMIN)
    @GetMapping
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<OffenseInformation>>> getOffensesInformation() {
        return CompletableFuture.supplyAsync(() -> {
            List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
            return ResponseEntity.ok(offensesInformation);
        }, virtualThreadExecutor);
    }

    // 更新指定违法行为的信息 (仅 ADMIN)
    @PutMapping("/{offenseId}")
    @Async
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<OffenseInformation>> updateOffense(@PathVariable int offenseId, @RequestBody OffenseInformation updatedOffenseInformation, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
            if (existingOffenseInformation != null) {
                updatedOffenseInformation.setOffenseId(offenseId);
                offenseInformationService.checkAndInsertIdempotency(idempotencyKey, updatedOffenseInformation, "update");
                return ResponseEntity.ok(updatedOffenseInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除指定违法行为的信息 (仅 ADMIN)
    @DeleteMapping("/{offenseId}")
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> deleteOffense(@PathVariable int offenseId) {
        return CompletableFuture.supplyAsync(() -> {
            offenseInformationService.deleteOffense(offenseId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据时间范围获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<OffenseInformation>>> getOffensesByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        return CompletableFuture.supplyAsync(() -> {
            List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
            return ResponseEntity.ok(offenses);
        }, virtualThreadExecutor);
    }

    // 根据处理状态获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/processState/{processState}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<OffenseInformation>>> getOffensesByProcessState(@PathVariable String processState) {
        return CompletableFuture.supplyAsync(() -> {
            List<OffenseInformation> offenses = offenseInformationService.getOffensesByProcessState(processState);
            return ResponseEntity.ok(offenses);
        }, virtualThreadExecutor);
    }

    // 根据司机姓名获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/driverName/{driverName}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<OffenseInformation>>> getOffensesByDriverName(@PathVariable String driverName) {
        return CompletableFuture.supplyAsync(() -> {
            List<OffenseInformation> offenses = offenseInformationService.getOffensesByDriverName(driverName);
            return ResponseEntity.ok(offenses);
        }, virtualThreadExecutor);
    }

    // 根据车牌号获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/licensePlate/{licensePlate}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<OffenseInformation>>> getOffensesByLicensePlate(@PathVariable String licensePlate) {
        return CompletableFuture.supplyAsync(() -> {
            List<OffenseInformation> offenses = offenseInformationService.getOffensesByLicensePlate(licensePlate);
            return ResponseEntity.ok(offenses);
        }, virtualThreadExecutor);
    }
}