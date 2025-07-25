package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.TrafficViolationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/traffic-violations")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Traffic Violations", description = "APIs for retrieving traffic violation statistics")
public class TrafficViolationController {

    private static final Logger logger = LoggerFactory.getLogger(TrafficViolationController.class);
    private final TrafficViolationService trafficViolationService;

    @Autowired
    public TrafficViolationController(TrafficViolationService trafficViolationService) {
        this.trafficViolationService = trafficViolationService;
    }

    @GetMapping("/violation-types")
    @PreAuthorize("hasAnyRole('ADMIN')")
    @Operation(
            summary = "按违法类型统计",
            description = "获取按违法类型统计的数量，ADMIN 角色可访问。支持按开始时间、驾驶员姓名和车牌号过滤。返回格式为 Map<offenseType, count>。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违法类型统计数据"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数（如时间格式错误）"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Map<String, Integer>> getViolationTypeCounts(
            @RequestParam(required = false) @Parameter(description = "开始时间，格式：yyyy-MM-dd", example = "2023-01-01") String startTime,
            @RequestParam(required = false) @Parameter(description = "驾驶员姓名", example = "John Doe") String driverName,
            @RequestParam(required = false) @Parameter(description = "车牌号", example = "ABC123") String licensePlate) {
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

    @GetMapping("/time-series")
    @PreAuthorize("hasAnyRole('ADMIN')")
    @Operation(
            summary = "按天统计罚款和扣分时序数据",
            description = "获取按天的罚款总额和扣分总数时序数据，ADMIN 角色可访问。支持按开始时间和驾驶员姓名过滤。返回格式为 List<Map<time: yyyy-MM-dd, value1: totalFine, value2: totalPoints>>。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回时序数据"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数（如时间格式错误）"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<Map<String, Object>>> getTimeSeriesData(
            @RequestParam(required = false) @Parameter(description = "开始时间，格式：yyyy-MM-dd", example = "2023-01-01") String startTime,
            @RequestParam(required = false) @Parameter(description = "驾驶员姓名", example = "John Doe") String driverName) {
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

    @GetMapping("/appeal-reasons")
    @PreAuthorize("hasAnyRole('ADMIN')")
    @Operation(
            summary = "按申诉原因统计",
            description = "获取按申诉原因统计的数量，ADMIN 角色可访问。支持按开始时间和申诉原因过滤。返回格式为 Map<appealReason, count>。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回申诉原因统计数据"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数（如时间格式错误）"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Map<String, Integer>> getAppealReasonCounts(
            @RequestParam(required = false) @Parameter(description = "开始时间，格式：yyyy-MM-dd", example = "2023-01-01") String startTime,
            @RequestParam(required = false) @Parameter(description = "申诉原因", example = "Incorrect Data") String appealReason) {
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

    @GetMapping("/fine-payment-status")
    @PreAuthorize("hasAnyRole('ADMIN')")
    @Operation(
            summary = "按罚款支付状态统计",
            description = "获取按罚款支付状态（已支付/未支付）统计的数量，ADMIN 角色可访问。支持按开始时间过滤。返回格式为 Map<\"Paid\"/\"Unpaid\", count>。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回罚款支付状态统计数据"),
            @ApiResponse(responseCode = "400", description = "无效的输入参数（如时间格式错误）"),
            @ApiResponse(responseCode = "403", description = "无权限访问，仅限 ADMIN 角色"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Map<String, Integer>> getFinePaymentStatus(
            @RequestParam(required = false) @Parameter(description = "开始时间，格式：yyyy-MM-dd", example = "2023-01-01") String startTime) {
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