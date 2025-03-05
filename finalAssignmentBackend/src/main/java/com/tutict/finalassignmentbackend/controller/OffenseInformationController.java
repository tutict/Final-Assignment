package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/api/offenses")
public class OffenseInformationController {

    private final OffenseInformationService offenseInformationService;

    public OffenseInformationController(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    // 创建新的违法行为信息 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createOffense(@RequestBody OffenseInformation offenseInformation, @RequestParam String idempotencyKey) {
        offenseInformationService.checkAndInsertIdempotency(idempotencyKey, offenseInformation, "create");
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据违法行为ID获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/{offenseId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<OffenseInformation> getOffenseByOffenseId(@PathVariable int offenseId) {
        OffenseInformation offenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (offenseInformation != null) {
            return ResponseEntity.ok(offenseInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 获取所有违法行为的信息 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> getOffensesInformation() {
        List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
        return ResponseEntity.ok(offensesInformation);
    }

    // 更新指定违法行为的信息 (仅 ADMIN)
    @PutMapping("/{offenseId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<OffenseInformation> updateOffense(@PathVariable int offenseId, @RequestBody OffenseInformation updatedOffenseInformation, @RequestParam String idempotencyKey) {
        OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (existingOffenseInformation != null) {
            updatedOffenseInformation.setOffenseId(offenseId);
            offenseInformationService.checkAndInsertIdempotency(idempotencyKey, updatedOffenseInformation, "update");
            return ResponseEntity.ok(updatedOffenseInformation);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 删除指定违法行为的信息 (仅 ADMIN)
    @DeleteMapping("/{offenseId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteOffense(@PathVariable int offenseId) {
        offenseInformationService.deleteOffense(offenseId);
        return ResponseEntity.noContent().build();
    }

    // 根据时间范围获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> getOffensesByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
        return ResponseEntity.ok(offenses);
    }

    // 根据处理状态获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/processState/{processState}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> getOffensesByProcessState(@PathVariable String processState) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByProcessState(processState);
        return ResponseEntity.ok(offenses);
    }

    // 根据司机姓名获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/driverName/{driverName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> getOffensesByDriverName(@PathVariable String driverName) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByDriverName(driverName);
        return ResponseEntity.ok(offenses);
    }

    // 根据车牌号获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/licensePlate/{licensePlate}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> getOffensesByLicensePlate(@PathVariable String licensePlate) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByLicensePlate(licensePlate);
        return ResponseEntity.ok(offenses);
    }
}