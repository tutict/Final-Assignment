package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.TrafficViolationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/traffic-violations")
public class TrafficViolationController {

    private static final Logger logger = LoggerFactory.getLogger(TrafficViolationController.class);
    private final TrafficViolationService trafficViolationService;

    @Autowired
    public TrafficViolationController(TrafficViolationService trafficViolationService) {
        this.trafficViolationService = trafficViolationService;
    }

    /**
     * 按违法类型统计
     * 返回 Map<offenseType, count>
     */
    @GetMapping("/violation-types")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<Map<String, Integer>> getViolationTypeCounts(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String driverName,
            @RequestParam(required = false) String licensePlate) {
        try {
            logger.info("Fetching violation type counts: startTime={}, driverName={}, licensePlate={}",
                    startTime, driverName, licensePlate);
            Map<String, Integer> counts = trafficViolationService
                    .getViolationTypeCounts(startTime, driverName, licensePlate);
            return ResponseEntity.ok(counts);
        } catch (IllegalArgumentException e) {
            logger.warn("Bad request for violation-type counts: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Collections.singletonMap("error_code", 400));
        } catch (Exception e) {
            logger.error("Error fetching violation type counts", e);
            return ResponseEntity.status(500)
                    .body(Collections.singletonMap("error_code", 500));
        }
    }

    /**
     * 按天统计罚款总额和扣分总数（时序数据）
     * 返回 List<{ time: yyyy-MM-dd, value1: totalFine, value2: totalPoints }>
     */
    @GetMapping("/time-series")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<List<Map<String, Object>>> getTimeSeriesData(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String driverName) {
        try {
            logger.info("Fetching time series data: startTime={}, driverName={}", startTime, driverName);
            List<Map<String, Object>> data = trafficViolationService.getTimeSeriesData(startTime, driverName);
            return ResponseEntity.ok(data);
        } catch (IllegalArgumentException e) {
            logger.warn("Bad request for time-series data: {}", e.getMessage());
            Map<String, Object> err = new HashMap<>();
            err.put("error_code", 400);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(Collections.singletonList(err));
        } catch (Exception e) {
            logger.error("Error fetching time-series data", e);
            Map<String, Object> err = new HashMap<>();
            err.put("error_code", 500);
            err.put("message", e.getMessage());
            return ResponseEntity.status(500).body(Collections.singletonList(err));
        }
    }

    /**
     * 按申诉原因统计
     * 返回 Map<appealReason, count>
     */
    @GetMapping("/appeal-reasons")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<Map<String, Integer>> getAppealReasonCounts(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String appealReason) {
        try {
            logger.info("Fetching appeal reason counts: startTime={}, appealReason={}", startTime, appealReason);
            Map<String, Integer> counts = trafficViolationService.getAppealReasonCounts(startTime, appealReason);
            return ResponseEntity.ok(counts);
        } catch (IllegalArgumentException e) {
            logger.warn("Bad request for appeal-reason counts: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Collections.singletonMap("error_code", 400));
        } catch (Exception e) {
            logger.error("Error fetching appeal-reason counts", e);
            return ResponseEntity.status(500)
                    .body(Collections.singletonMap("error_code", 500));
        }
    }

    /**
     * 按罚款支付状态统计
     * 返回 Map<"Paid"/"Unpaid", count>
     */
    @GetMapping("/fine-payment-status")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<Map<String, Integer>> getFinePaymentStatus(
            @RequestParam(required = false) String startTime) {
        try {
            logger.info("Fetching fine payment status: startTime={}", startTime);
            Map<String, Integer> status = trafficViolationService.getFinePaymentStatus(startTime);
            return ResponseEntity.ok(status);
        } catch (IllegalArgumentException e) {
            logger.warn("Bad request for fine-payment-status: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Collections.singletonMap("error_code", 400));
        } catch (Exception e) {
            logger.error("Error fetching fine-payment-status", e);
            return ResponseEntity.status(500)
                    .body(Collections.singletonMap("error_code", 500));
        }
    }
}
