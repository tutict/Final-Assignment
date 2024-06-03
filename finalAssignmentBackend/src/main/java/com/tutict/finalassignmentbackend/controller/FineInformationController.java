package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/eventbus/fines")
public class FineInformationController {

    private final FineInformationService fineInformationService;

    @Autowired
    public FineInformationController(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    @PostMapping
    public ResponseEntity<Void> createFine(@RequestBody FineInformation fineInformation) {
        fineInformationService.createFine(fineInformation);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{fineId}")
    public ResponseEntity<FineInformation> getFineById(@PathVariable int fineId) {
        FineInformation fineInformation = fineInformationService.getFineById(fineId);
        if (fineInformation != null) {
            return ResponseEntity.ok(fineInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<FineInformation>> getAllFines() {
        List<FineInformation> fines = fineInformationService.getAllFines();
        return ResponseEntity.ok(fines);
    }

    @PutMapping("/{fineId}")
    public ResponseEntity<Void> updateFine(@PathVariable int fineId, @RequestBody FineInformation updatedFineInformation) {
        FineInformation existingFineInformation = fineInformationService.getFineById(fineId);
        if (existingFineInformation != null) {

            existingFineInformation.setBank(updatedFineInformation.getBank());
            existingFineInformation.setReceiptNumber(updatedFineInformation.getReceiptNumber());
            existingFineInformation.setPayee(updatedFineInformation.getPayee());
            existingFineInformation.setRemarks(updatedFineInformation.getRemarks());
            existingFineInformation.setFineAmount(updatedFineInformation.getFineAmount());
            existingFineInformation.setFineTime(updatedFineInformation.getFineTime());
            existingFineInformation.setAccountNumber(updatedFineInformation.getAccountNumber());


            fineInformationService.updateFine(updatedFineInformation);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{fineId}")
    public ResponseEntity<Void> deleteFine(@PathVariable int fineId) {
        fineInformationService.deleteFine(fineId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/payee/{payee}")
    public ResponseEntity<List<FineInformation>> getFinesByPayee(@PathVariable String payee) {
        List<FineInformation> fines = fineInformationService.getFinesByPayee(payee);
        return ResponseEntity.ok(fines);
    }

    @GetMapping("/timeRange")
    public ResponseEntity<List<FineInformation>> getFinesByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<FineInformation> fines = fineInformationService.getFinesByTimeRange(startTime, endTime);
        return ResponseEntity.ok(fines);
    }

    @GetMapping("/receiptNumber/{receiptNumber}")
    public ResponseEntity<FineInformation> getFineByReceiptNumber(@PathVariable String receiptNumber) {
        FineInformation fineInformation = fineInformationService.getFineByReceiptNumber(receiptNumber);
        if (fineInformation != null) {
            return ResponseEntity.ok(fineInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
