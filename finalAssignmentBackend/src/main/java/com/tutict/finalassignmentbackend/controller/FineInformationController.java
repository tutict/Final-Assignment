package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
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
@RequestMapping("/api/fines")
public class FineInformationController {

    private static final Logger logger = Logger.getLogger(FineInformationController.class.getName());

    private final FineInformationService fineInformationService;

    public FineInformationController(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    // 创建新的罚款记录 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createFine(@RequestBody FineInformation fineInformation, @RequestParam String idempotencyKey) {
        fineInformationService.checkAndInsertIdempotency(idempotencyKey, fineInformation, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据罚款ID获取罚款信息 (USER 和 ADMIN)
    @GetMapping("/{fineId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<FineInformation> getFineById(@PathVariable int fineId) {
        FineInformation fineInformation = fineInformationService.getFineById(fineId);
        if (fineInformation != null) {
            return ResponseEntity.ok(fineInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有罚款信息 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<FineInformation>> getAllFines() {
        List<FineInformation> fines = fineInformationService.getAllFines();
        return ResponseEntity.ok(fines);
    }

    // 更新罚款信息 (仅 ADMIN)
    @PutMapping("/{fineId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FineInformation> updateFine(@PathVariable int fineId, @RequestBody FineInformation updatedFineInformation, @RequestParam String idempotencyKey) {
        FineInformation existingFineInformation = fineInformationService.getFineById(fineId);
        if (existingFineInformation != null) {
            updatedFineInformation.setFineId(fineId);
            fineInformationService.checkAndInsertIdempotency(idempotencyKey, updatedFineInformation, "update");
            return ResponseEntity.ok(updatedFineInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除指定ID的罚款记录 (仅 ADMIN)
    @DeleteMapping("/{fineId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteFine(@PathVariable int fineId) {
        fineInformationService.deleteFine(fineId);
        return ResponseEntity.noContent().build();
    }

    // 根据支付方获取罚款记录 (USER 和 ADMIN)
    @GetMapping("/payee/{payee}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<FineInformation>> getFinesByPayee(@PathVariable String payee) {
        List<FineInformation> fines = fineInformationService.getFinesByPayee(payee);
        return ResponseEntity.ok(fines);
    }

    // 根据时间范围获取罚款记录 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<FineInformation>> getFinesByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        List<FineInformation> fines = fineInformationService.getFinesByTimeRange(startTime, endTime);
        return ResponseEntity.ok(fines);
    }

    // 根据收据编号获取罚款信息 (USER 和 ADMIN)
    @GetMapping("/receiptNumber/{receiptNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<FineInformation> getFineByReceiptNumber(@PathVariable String receiptNumber) {
        FineInformation fineInformation = fineInformationService.getFineByReceiptNumber(receiptNumber);
        if (fineInformation != null) {
            return ResponseEntity.ok(fineInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/by-time-range")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<FineInformation>> searchByFineTimeRange(
            @RequestParam String startTime,
            @RequestParam String endTime,
            @RequestParam(defaultValue = "10") int maxSuggestions) {

        logger.log(Level.INFO, "Received request to search fines by time range: startTime={0}, endTime={1}, maxSuggestions={2}",
                new Object[]{startTime, endTime, maxSuggestions});

        try {
            List<FineInformation> results = fineInformationService.searchByFineTimeRange(startTime, endTime, maxSuggestions);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No fines found for time range: {0} to {1}",
                        new Object[]{startTime, endTime});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} fines for time range: {1} to {2}",
                    new Object[]{results.size(), startTime, endTime});
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by time range: startTime={0}, endTime={1}, error: {2}",
                    new Object[]{startTime, endTime, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }
}