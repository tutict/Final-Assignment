package com.tutict.finalassignmentbackend.controller.view;

import com.tutict.finalassignmentbackend.entity.OffenseDetails;
import com.tutict.finalassignmentbackend.service.view.OffenseDetailsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/offense-details")
@Tag(name = "Offense Details", description = "APIs for managing and querying offense details")
public class OffenseDetailsController {

    private final OffenseDetailsService offenseDetailsService;

    public OffenseDetailsController(OffenseDetailsService offenseDetailsService) {
        this.offenseDetailsService = offenseDetailsService;
    }

    @GetMapping
    @Operation(
            summary = "获取所有违规详情记录",
            description = "获取所有违规详情记录的列表。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违规详情记录列表"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OffenseDetails>> getAllOffenseDetails() {
        try {
            List<OffenseDetails> offenseDetailsList = offenseDetailsService.getAllOffenseDetails();
            return ResponseEntity.ok(offenseDetailsList);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }

    @GetMapping("/{id}")
    @Operation(
            summary = "根据ID获取违规详情",
            description = "根据指定的违规详情ID获取记录。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违规详情记录"),
            @ApiResponse(responseCode = "404", description = "未找到指定的违规详情记录"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<OffenseDetails> getOffenseDetailsById(
            @PathVariable @Parameter(description = "违规详情ID", required = true, example = "1") Integer id) {
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

    @GetMapping("/offense-type-counts")
    @Operation(
            summary = "获取违规类型统计",
            description = "根据时间范围和可选的驾驶员姓名，获取违规类型的统计数据，返回每种违规类型的计数。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回违规类型统计数据"),
            @ApiResponse(responseCode = "400", description = "无效的时间参数或驾驶员姓名"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Map<String, Long>> getOffenseTypeCounts(
            @RequestParam @Parameter(description = "开始时间（ISO 8601 格式）", required = true, example = "2025-01-01T00:00:00") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam @Parameter(description = "结束时间（ISO 8601 格式）", required = true, example = "2025-12-31T23:59:59") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime,
            @RequestParam(required = false) @Parameter(description = "驾驶员姓名（可选）", example = "John Doe") String driverName) {
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

    @GetMapping("/vehicle-type-counts")
    @Operation(
            summary = "获取车辆类型统计",
            description = "根据时间范围和可选的车牌号，获取车辆类型的统计数据，返回每种车辆类型的计数。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回车辆类型统计数据"),
            @ApiResponse(responseCode = "400", description = "无效的时间参数或车牌号"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<Map<String, Long>> getVehicleTypeCounts(
            @RequestParam @Parameter(description = "开始时间（ISO 8601 格式）", required = true, example = "2025-01-01T00:00:00") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam @Parameter(description = "结束时间（ISO 8601 格式）", required = true, example = "2025-12-31T23:59:59") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime,
            @RequestParam(required = false) @Parameter(description = "车牌号（可选）", example = "ABC123") String licensePlate) {
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

    @GetMapping("/search")
    @Operation(
            summary = "多条件搜索违规详情",
            description = "根据驾驶员姓名、车牌号、违规类型和时间范围（均可选）搜索违规详情记录。"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "成功返回符合条件的违规详情记录列表"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    public ResponseEntity<List<OffenseDetails>> searchOffenseDetails(
            @RequestParam(required = false) @Parameter(description = "驾驶员姓名（可选）", example = "John Doe") String driverName,
            @RequestParam(required = false) @Parameter(description = "车牌号（可选）", example = "ABC123") String licensePlate,
            @RequestParam(required = false) @Parameter(description = "违规类型（可选）", example = "Speeding") String offenseType,
            @RequestParam(required = false) @Parameter(description = "开始时间（ISO 8601 格式，可选）", example = "2025-01-01T00:00:00") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startTime,
            @RequestParam(required = false) @Parameter(description = "结束时间（ISO 8601 格式，可选）", example = "2025-12-31T23:59:59") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endTime) {
        try {
            List<OffenseDetails> results = offenseDetailsService.findByCriteria(driverName, licensePlate, offenseType, startTime, endTime);
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }
}