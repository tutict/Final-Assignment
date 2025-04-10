package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.TrafficViolationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/traffic-violations")
public class TrafficViolationController {

    private static final Logger logger = LoggerFactory.getLogger(TrafficViolationController.class);
    private final TrafficViolationService trafficViolationService;

    @Autowired
    public TrafficViolationController(TrafficViolationService trafficViolationService) {
        this.trafficViolationService = trafficViolationService;
    }

    @GetMapping("/violation-types")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<Map<String, Integer>> getViolationTypeCounts(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String driverName,
            @RequestParam(required = false) String licensePlate) {
        try {
            logger.info("Fetching violation type counts with startTime: {}, driverName: {}, licensePlate: {}",
                    startTime, driverName, licensePlate);
            // 从 service 层获取 Map<String, Long>
            Map<String, Long> violationTypeCountsLong = trafficViolationService.getViolationTypeCounts(startTime, driverName, licensePlate);

            // 转换 Map<String, Long> 为 Map<String, Integer>
            Map<String, Integer> violationTypeCounts = violationTypeCountsLong.entrySet()
                    .stream()
                    .collect(Collectors.toMap(
                            Map.Entry::getKey,
                            e -> e.getValue().intValue() // 注意：确保 Long 的值不会超出 Integer 范围
                    ));

            logger.debug("Violation type counts retrieved: {}", violationTypeCounts);
            return ResponseEntity.ok(violationTypeCounts);
        } catch (IllegalStateException e) {
            logger.warn("Bad request for violation type counts: {}", e.getMessage());
            return ResponseEntity.badRequest().body(createErrorMapForCounts(400, e.getMessage()));
        } catch (Exception e) {
            logger.error("Error fetching violation type counts: {}", e.getMessage(), e);
            return ResponseEntity.status(500).body(createErrorMapForCounts(500, e.getMessage()));
        }
    }

    @GetMapping("/time-series")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<List<Map<String, Object>>> getTimeSeriesData(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String driverName) {
        try {
            logger.info("Fetching time series data with startTime: {}, driverName: {}", startTime, driverName);
            List<Map<String, Object>> timeSeriesData = trafficViolationService.getTimeSeriesData(startTime, driverName);
            logger.debug("Time series data retrieved: {}", timeSeriesData);
            return ResponseEntity.ok(timeSeriesData);
        } catch (IllegalStateException e) {
            logger.warn("Bad request for time series data: {}", e.getMessage());
            return ResponseEntity.badRequest().body(List.of(createErrorMap(400, e.getMessage())));
        } catch (Exception e) {
            logger.error("Error fetching time series data: {}", e.getMessage(), e);
            return ResponseEntity.status(500).body(List.of(createErrorMap(500, e.getMessage())));
        }
    }

    @GetMapping("/appeal-reasons")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<Map<String, Integer>> getAppealReasonCounts(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String appealReason) {
        try {
            logger.info("Fetching appeal reason counts with startTime: {}, appealReason: {}", startTime, appealReason);
            Map<String, Integer> appealReasonCounts = trafficViolationService.getAppealReasonCounts(startTime, appealReason);
            logger.debug("Appeal reason counts retrieved: {}", appealReasonCounts);
            return ResponseEntity.ok(appealReasonCounts);
        } catch (IllegalStateException e) {
            logger.warn("Bad request for appeal reason counts: {}", e.getMessage());
            return ResponseEntity.badRequest().body(createErrorMapForCounts(400, e.getMessage()));
        } catch (Exception e) {
            logger.error("Error fetching appeal reason counts: {}", e.getMessage(), e);
            return ResponseEntity.status(500).body(createErrorMapForCounts(500, e.getMessage()));
        }
    }

    @GetMapping("/fine-payment-status")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<Map<String, Integer>> getFinePaymentStatus(
            @RequestParam(required = false) String startTime) {
        try {
            logger.info("Fetching fine payment status with startTime: {}", startTime);
            Map<String, Integer> finePaymentStatus = trafficViolationService.getFinePaymentStatus(startTime);
            logger.debug("Fine payment status retrieved: {}", finePaymentStatus);
            return ResponseEntity.ok(finePaymentStatus);
        } catch (IllegalStateException e) {
            logger.warn("Bad request for fine payment status: {}", e.getMessage());
            return ResponseEntity.badRequest().body(createErrorMapForCounts(400, e.getMessage()));
        } catch (Exception e) {
            logger.error("Error fetching fine payment status: {}", e.getMessage(), e);
            return ResponseEntity.status(500).body(createErrorMapForCounts(500, e.getMessage()));
        }
    }

    private Map<String, Integer> createErrorMapForCounts(int errorCode, String message) {
        Map<String, Integer> errorMap = new HashMap<>();
        errorMap.put("error_code", errorCode);
        logger.debug("Error message for code {}: {}", errorCode, message);
        return errorMap;
    }

    private Map<String, Object> createErrorMap(int errorCode, String message) {
        Map<String, Object> errorMap = new HashMap<>();
        errorMap.put("error_code", errorCode);
        errorMap.put("message", message);
        return errorMap;
    }
}