package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Level;

@RestController
@RequestMapping("/api/deductions")
public class DeductionInformationController {

    private static final Logger logger = Logger.getLogger(DeductionInformationController.class.getName());

    private final DeductionInformationService deductionInformationService;

    public DeductionInformationController(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    // 创建新的扣除记录 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createDeduction(@RequestBody DeductionInformation deduction, @RequestParam String idempotencyKey) {
        logger.info("Attempting to create deduction with idempotency key: " + idempotencyKey);
        deductionInformationService.checkAndInsertIdempotency(idempotencyKey, deduction, "create");
        logger.info("Deduction created successfully.");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据扣除ID获取扣除信息 (USER 和 ADMIN)
    @GetMapping("/{deductionId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<DeductionInformation> getDeductionById(@PathVariable int deductionId) {
        DeductionInformation deduction = deductionInformationService.getDeductionById(deductionId);
        if (deduction != null) {
            return ResponseEntity.ok(deduction);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有扣除记录 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<DeductionInformation>> getAllDeductions() {
        List<DeductionInformation> deductions = deductionInformationService.getAllDeductions();
        return ResponseEntity.ok(deductions);
    }

    // 更新扣除记录 (仅 ADMIN)
    @PutMapping("/{deductionId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> updateDeduction(@PathVariable int deductionId, @RequestBody DeductionInformation updatedDeduction, @RequestParam String idempotencyKey) {
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
    }

    // 删除扣除记录 (仅 ADMIN)
    @DeleteMapping("/{deductionId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteDeduction(@PathVariable int deductionId) {
        deductionInformationService.deleteDeduction(deductionId);
        return ResponseEntity.noContent().build();
    }

    // 根据处理人获取扣除记录 (USER 和 ADMIN)
    @GetMapping("/handler/{handler}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<DeductionInformation>> getDeductionsByHandler(@PathVariable String handler) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByHandler(handler);
        return ResponseEntity.ok(deductions);
    }

    // 根据时间范围获取扣除记录 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<DeductionInformation>> getDeductionsByTimeRange(@RequestParam Date startTime, @RequestParam Date endTime) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByTimeRange(startTime, endTime);
        return ResponseEntity.ok(deductions);
    }

    @GetMapping("/by-handler")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<DeductionInformation>> searchByHandler(
            @RequestParam String handler,
            @RequestParam(defaultValue = "10") int maxSuggestions) {

        logger.log(Level.INFO, "Received request to search deductions by handler: {0}, maxSuggestions: {1}",
                new Object[]{handler, maxSuggestions});

        try {
            List<DeductionInformation> results = deductionInformationService.searchByHandler(handler, maxSuggestions);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No deductions found for handler: {0}", new Object[]{handler});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} deductions for handler: {1}",
                    new Object[]{results.size(), handler});
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by handler: {0}, error: {1}",
                    new Object[]{handler, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    @GetMapping("/by-time-range")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<DeductionInformation>> searchByDeductionTimeRange(
            @RequestParam String startTime,
            @RequestParam String endTime,
            @RequestParam(defaultValue = "10") int maxSuggestions) {

        logger.log(Level.INFO, "Received request to search deductions by time range: startTime={0}, endTime={1}, maxSuggestions={2}",
                new Object[]{startTime, endTime, maxSuggestions});

        try {
            List<DeductionInformation> results = deductionInformationService.searchByDeductionTimeRange(startTime, endTime, maxSuggestions);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No deductions found for time range: {0} to {1}",
                        new Object[]{startTime, endTime});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} deductions for time range: {1} to {2}",
                    new Object[]{results.size(), startTime, endTime});
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by time range: startTime={0}, endTime={1}, error: {2}",
                    new Object[]{startTime, endTime, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }
}