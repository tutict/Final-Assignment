package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
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

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/deductions")
public class DeductionInformationController {

    private static final Logger logger = Logger.getLogger(DeductionInformationController.class.getName());

    // 创建虚拟线程池
    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final DeductionInformationService deductionInformationService;

    public DeductionInformationController(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    // 创建新的扣除记录
    @PostMapping
    @Async
    public CompletableFuture<ResponseEntity<Void>> createDeduction(@RequestBody DeductionInformation deduction, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Attempting to create deduction with idempotency key: " + idempotencyKey);
            deductionInformationService.checkAndInsertIdempotency(idempotencyKey, deduction, "create");
            logger.info("Deduction created successfully.");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    // 根据扣除ID获取扣除信息
    @GetMapping("/{deductionId}")
    @Async
    public CompletableFuture<ResponseEntity<DeductionInformation>> getDeductionById(@PathVariable int deductionId) {
        return CompletableFuture.supplyAsync(() -> {
            DeductionInformation deduction = deductionInformationService.getDeductionById(deductionId);
            if (deduction != null) {
                return ResponseEntity.ok(deduction);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 获取所有扣除记录
    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<DeductionInformation>>> getAllDeductions() {
        return CompletableFuture.supplyAsync(() -> {
            List<DeductionInformation> deductions = deductionInformationService.getAllDeductions();
            return ResponseEntity.ok(deductions);
        }, virtualThreadExecutor);
    }

    // 更新扣除记录
    @PutMapping("/{deductionId}")
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<Void>> updateDeduction(@PathVariable int deductionId, @RequestBody DeductionInformation updatedDeduction, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            DeductionInformation existingDeduction = deductionInformationService.getDeductionById(deductionId);
            if (existingDeduction != null) {
                existingDeduction.setRemarks(updatedDeduction.getRemarks());
                existingDeduction.setHandler(updatedDeduction.getHandler());
                existingDeduction.setDeductedPoints(updatedDeduction.getDeductedPoints());
                existingDeduction.setDeductionTime(updatedDeduction.getDeductionTime());
                existingDeduction.setApprover(updatedDeduction.getApprover());

                deductionInformationService.checkAndInsertIdempotency(idempotencyKey, existingDeduction, "update");
                return ResponseEntity.ok().build();
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    // 删除扣除记录
    @DeleteMapping("/{deductionId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteDeduction(@PathVariable int deductionId) {
        return CompletableFuture.supplyAsync(() -> {
            deductionInformationService.deleteDeduction(deductionId);
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    // 根据处理人获取扣除记录
    @GetMapping("/handler/{handler}")
    @Async
    public CompletableFuture<ResponseEntity<List<DeductionInformation>>> getDeductionsByHandler(@PathVariable String handler) {
        return CompletableFuture.supplyAsync(() -> {
            List<DeductionInformation> deductions = deductionInformationService.getDeductionsByHandler(handler);
            return ResponseEntity.ok(deductions);
        }, virtualThreadExecutor);
    }

    // 根据时间范围获取扣除记录
    @GetMapping("/timeRange")
    @Async
    public CompletableFuture<ResponseEntity<List<DeductionInformation>>> getDeductionsByTimeRange(@RequestParam Date startTime, @RequestParam Date endTime) {
        return CompletableFuture.supplyAsync(() -> {
            List<DeductionInformation> deductions = deductionInformationService.getDeductionsByTimeRange(startTime, endTime);
            return ResponseEntity.ok(deductions);
        }, virtualThreadExecutor);
    }
}
