package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.TrafficViolationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/traffic-violations")
public class TrafficViolationController {

    private final TrafficViolationService trafficViolationService;

    @Autowired
    public TrafficViolationController(TrafficViolationService trafficViolationService) {
        this.trafficViolationService = trafficViolationService;
    }

    @GetMapping("/violation-types")
    public ResponseEntity<Map<String, Integer>> getViolationTypeCounts(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String driverName,
            @RequestParam(required = false) String licensePlate) {
        try {
            Map<String, Integer> violationTypeCounts = trafficViolationService.getViolationTypeCounts(startTime, driverName, licensePlate);
            return ResponseEntity.ok(violationTypeCounts);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("error_code", 400));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error_code", 500));
        }
    }

    @GetMapping("/time-series")
    public ResponseEntity<List<Map<String, Object>>> getTimeSeriesData(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String driverName) {
        try {
            List<Map<String, Object>> timeSeriesData = trafficViolationService.getTimeSeriesData(startTime, driverName);
            return ResponseEntity.ok(timeSeriesData);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(List.of(Map.of("error_code", 400)));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(List.of(Map.of("error_code", 500)));
        }
    }

    @GetMapping("/appeal-reasons")
    public ResponseEntity<Map<String, Integer>> getAppealReasonCounts(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String appealReason) {
        try {
            Map<String, Integer> appealReasonCounts = trafficViolationService.getAppealReasonCounts(startTime, appealReason);
            return ResponseEntity.ok(appealReasonCounts);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("error_code", 400));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error_code", 500));
        }
    }

    @GetMapping("/fine-payment-status")
    public ResponseEntity<Map<String, Integer>> getFinePaymentStatus(
            @RequestParam(required = false) String startTime) {
        try {
            Map<String, Integer> finePaymentStatus = trafficViolationService.getFinePaymentStatus(startTime);
            return ResponseEntity.ok(finePaymentStatus);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("error_code", 400));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error_code", 500));
        }
    }
}