package com.tutict.finalassignmentbackend.controller.view;

import com.tutict.finalassignmentbackend.entity.OffenseDetails;
import com.tutict.finalassignmentbackend.service.view.OffenseDetailsService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/offense-details")
public class OffenseDetailsController {

    private final OffenseDetailsService offenseDetailsService;

    public OffenseDetailsController(OffenseDetailsService offenseDetailsService) {
        this.offenseDetailsService = offenseDetailsService;
    }

    // 获取所有违规详情记录
    @GetMapping
    public ResponseEntity<List<OffenseDetails>> getAllOffenseDetails() {
        try {
            List<OffenseDetails> offenseDetailsList = offenseDetailsService.getAllOffenseDetails();
            return ResponseEntity.ok(offenseDetailsList);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }

    // 根据 ID 获取违规详情
    @GetMapping("/{id}")
    public ResponseEntity<OffenseDetails> getOffenseDetailsById(@PathVariable Integer id) {
        try {
            OffenseDetails offenseDetails = offenseDetailsService.getOffenseDetailsById(id);
            return ResponseEntity.ok(offenseDetails);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }

    // 获取违规类型统计
    @GetMapping("/offense-type-counts")
    public ResponseEntity<Map<String, Long>> getOffenseTypeCounts(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime,
            @RequestParam(required = false) String driverName) {
        try {
            Map<String, Long> counts = offenseDetailsService.getOffenseTypeCounts(startTime, endTime, driverName);
            return ResponseEntity.ok(counts);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }

    // 获取车辆类型统计
    @GetMapping("/vehicle-type-counts")
    public ResponseEntity<Map<String, Long>> getVehicleTypeCounts(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime,
            @RequestParam(required = false) String licensePlate) {
        try {
            Map<String, Long> counts = offenseDetailsService.getVehicleTypeCounts(startTime, endTime, licensePlate);
            return ResponseEntity.ok(counts);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }

    // 多条件搜索违规详情
    @GetMapping("/search")
    public ResponseEntity<List<OffenseDetails>> searchOffenseDetails(
            @RequestParam(required = false) String driverName,
            @RequestParam(required = false) String licensePlate,
            @RequestParam(required = false) String offenseType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime) {
        try {
            List<OffenseDetails> results = offenseDetailsService.findByCriteria(driverName, licensePlate, offenseType, startTime, endTime);
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }
}