package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/eventbus/deductions")
public class DeductionInformationController {

    private final DeductionInformationService deductionInformationService;

    @Autowired
    public DeductionInformationController(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    @PostMapping
    public ResponseEntity<Void> createDeduction(@RequestBody DeductionInformation deduction) {
        deductionInformationService.createDeduction(deduction);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{deductionId}")
    public ResponseEntity<DeductionInformation> getDeductionById(@PathVariable int deductionId) {
        DeductionInformation deduction = deductionInformationService.getDeductionById(deductionId);
        if (deduction != null) {
            return ResponseEntity.ok(deduction);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<DeductionInformation>> getAllDeductions() {
        List<DeductionInformation> deductions = deductionInformationService.getAllDeductions();
        return ResponseEntity.ok(deductions);
    }

    @PutMapping("/{deductionId}")
    public ResponseEntity<Void> updateDeduction(@PathVariable int deductionId, @RequestBody DeductionInformation updatedDeduction) {
        DeductionInformation existingDeduction = deductionInformationService.getDeductionById(deductionId);
        if (existingDeduction != null) {
            // Update the existing deduction
            existingDeduction.setRemarks(updatedDeduction.getRemarks());
            existingDeduction.setHandler(updatedDeduction.getHandler());
            existingDeduction.setDeductedPoints(updatedDeduction.getDeductedPoints());
            existingDeduction.setDeductionTime(updatedDeduction.getDeductionTime());
            existingDeduction.setApprover(updatedDeduction.getApprover());

            deductionInformationService.updateDeduction(updatedDeduction);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{deductionId}")
    public ResponseEntity<Void> deleteDeduction(@PathVariable int deductionId) {
        deductionInformationService.deleteDeduction(deductionId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/handler/{handler}")
    public ResponseEntity<List<DeductionInformation>> getDeductionsByHandler(@PathVariable String handler) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByHandler(handler);
        return ResponseEntity.ok(deductions);
    }

    @GetMapping("/timeRange")
    public ResponseEntity<List<DeductionInformation>> getDeductionsByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByByTimeRange(startTime, endTime);
        return ResponseEntity.ok(deductions);
    }
}