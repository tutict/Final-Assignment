package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
@RequestMapping("/api/fines")
public class FineInformationController {

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final FineInformationService fineInformationService;

    public FineInformationController(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    // 创建新的罚款记录 (仅 ADMIN)
    @PostMapping
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> createFine(@RequestBody FineInformation fineInformation, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            fineInformationService.checkAndInsertIdempotency(idempotencyKey, fineInformation, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据罚款ID获取罚款信息 (USER 和 ADMIN)
    @GetMapping("/{fineId}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<FineInformation>> getFineById(@PathVariable int fineId) {
        return CompletableFuture.supplyAsync(() -> {
            FineInformation fineInformation = fineInformationService.getFineById(fineId);
            if (fineInformation != null) {
                return ResponseEntity.ok(fineInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有罚款信息 (USER 和 ADMIN)
    @GetMapping
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<FineInformation>>> getAllFines() {
        return CompletableFuture.supplyAsync(() -> {
            List<FineInformation> fines = fineInformationService.getAllFines();
            return ResponseEntity.ok(fines);
        }, virtualThreadExecutor);
    }

    // 更新罚款信息 (仅 ADMIN)
    @PutMapping("/{fineId}")
    @Async
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<FineInformation>> updateFine(@PathVariable int fineId, @RequestBody FineInformation updatedFineInformation, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            FineInformation existingFineInformation = fineInformationService.getFineById(fineId);
            if (existingFineInformation != null) {
                updatedFineInformation.setFineId(fineId);
                fineInformationService.checkAndInsertIdempotency(idempotencyKey, updatedFineInformation, "update");
                return ResponseEntity.ok(updatedFineInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除指定ID的罚款记录 (仅 ADMIN)
    @DeleteMapping("/{fineId}")
    @Async
    @PreAuthorize("hasRole('ADMIN')")
    public CompletableFuture<ResponseEntity<Void>> deleteFine(@PathVariable int fineId) {
        return CompletableFuture.supplyAsync(() -> {
            fineInformationService.deleteFine(fineId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据支付方获取罚款记录 (USER 和 ADMIN)
    @GetMapping("/payee/{payee}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<FineInformation>>> getFinesByPayee(@PathVariable String payee) {
        return CompletableFuture.supplyAsync(() -> {
            List<FineInformation> fines = fineInformationService.getFinesByPayee(payee);
            return ResponseEntity.ok(fines);
        }, virtualThreadExecutor);
    }

    // 根据时间范围获取罚款记录 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<List<FineInformation>>> getFinesByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        return CompletableFuture.supplyAsync(() -> {
            List<FineInformation> fines = fineInformationService.getFinesByTimeRange(startTime, endTime);
            return ResponseEntity.ok(fines);
        }, virtualThreadExecutor);
    }

    // 根据收据编号获取罚款信息 (USER 和 ADMIN)
    @GetMapping("/receiptNumber/{receiptNumber}")
    @Async
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public CompletableFuture<ResponseEntity<FineInformation>> getFineByReceiptNumber(@PathVariable String receiptNumber) {
        return CompletableFuture.supplyAsync(() -> {
            FineInformation fineInformation = fineInformationService.getFineByReceiptNumber(receiptNumber);
            if (fineInformation != null) {
                return ResponseEntity.ok(fineInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }
}