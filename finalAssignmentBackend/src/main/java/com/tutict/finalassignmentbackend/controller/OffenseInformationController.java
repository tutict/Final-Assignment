package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Date;
import java.util.List;

// 控制器类，用于处理与违法行为信息相关的HTTP请求
@RestController
@RequestMapping("/eventbus/offenses")
public class OffenseInformationController {

    // 用于处理违法行为信息的服务
    private final OffenseInformationService offenseInformationService;

    // 构造函数注入OffenseInformationService
    @Autowired
    public OffenseInformationController(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    // 创建新的违法行为信息
    @PostMapping
    public ResponseEntity<Void> createOffense(@RequestBody OffenseInformation offenseInformation) {
        offenseInformationService.createOffense(offenseInformation);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据违法行为ID获取违法行为信息
    @GetMapping("/{offenseId}")
    public ResponseEntity<OffenseInformation> getOffenseByOffenseId(@PathVariable int offenseId) {
        OffenseInformation offenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (offenseInformation != null) {
            return ResponseEntity.ok(offenseInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有违法行为的信息
    @GetMapping
    public ResponseEntity<List<OffenseInformation>> getOffensesInformation() {
        List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
        return ResponseEntity.ok(offensesInformation);
    }

    // 更新指定违法行为的信息
    @PutMapping("/{offenseId}")
    public ResponseEntity<Void> updateOffense(@PathVariable int offenseId, @RequestBody OffenseInformation updatedOffenseInformation) {
        OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (existingOffenseInformation != null) {
            updatedOffenseInformation.setOffenseId(offenseId);
            offenseInformationService.updateOffense(updatedOffenseInformation);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除指定违法行为的信息
    @DeleteMapping("/{offenseId}")
    public ResponseEntity<Void> deleteOffense(@PathVariable int offenseId) {
        offenseInformationService.deleteOffense(offenseId);
        return ResponseEntity.noContent().build();
    }

    // 根据时间范围获取违法行为信息
    @GetMapping("/timeRange")
    public ResponseEntity<List<OffenseInformation>> getOffensesByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
        return ResponseEntity.ok(offenses);
    }

    // 根据处理状态获取违法行为信息
    @GetMapping("/processState/{processState}")
    public ResponseEntity<List<OffenseInformation>> getOffensesByProcessState(@PathVariable String processState) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByProcessState(processState);
        return ResponseEntity.ok(offenses);
    }

    // 根据司机姓名获取违法行为信息
    @GetMapping("/driverName/{driverName}")
    public ResponseEntity<List<OffenseInformation>> getOffensesByDriverName(@PathVariable String driverName) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByDriverName(driverName);
        return ResponseEntity.ok(offenses);
    }

    // 根据车牌号获取违法行为信息
    @GetMapping("/licensePlate/{licensePlate}")
    public ResponseEntity<List<OffenseInformation>> getOffensesByLicensePlate(@PathVariable String licensePlate) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByLicensePlate(licensePlate);
        return ResponseEntity.ok(offenses);
    }
}
