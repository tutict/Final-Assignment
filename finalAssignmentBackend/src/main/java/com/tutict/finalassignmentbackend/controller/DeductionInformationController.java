package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
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

// 控制器类，用于管理扣分信息相关的HTTP请求
@RestController
@RequestMapping("/eventbus/deductions")
public class DeductionInformationController {

    // 扣分信息服务的接口，用于执行扣分信息的CRUD操作
    private final DeductionInformationService deductionInformationService;

    // 构造函数注入扣分信息服务
    @Autowired
    public DeductionInformationController(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    // 创建新的扣分信息
    // @RequestBody 表示请求体中的数据，这里是指扣分信息对象
    // 返回状态为201 CREATED，表示已成功创建新的资源
    @PostMapping
    public ResponseEntity<Void> createDeduction(@RequestBody DeductionInformation deduction) {
        deductionInformationService.createDeduction(deduction);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据扣分ID获取扣分信息
    // @PathVariable 表示URL路径中的变量，这里是指扣分ID
    // 如果找到对应的扣分信息，返回状态为200 OK，否则返回状态为404 NOT_FOUND
    @GetMapping("/{deductionId}")
    public ResponseEntity<DeductionInformation> getDeductionById(@PathVariable int deductionId) {
        DeductionInformation deduction = deductionInformationService.getDeductionById(deductionId);
        if (deduction != null) {
            return ResponseEntity.ok(deduction);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有扣分信息列表
    // 返回状态为200 OK，包含扣分信息列表的响应体
    @GetMapping
    public ResponseEntity<List<DeductionInformation>> getAllDeductions() {
        List<DeductionInformation> deductions = deductionInformationService.getAllDeductions();
        return ResponseEntity.ok(deductions);
    }

    // 更新指定扣分ID的扣分信息
    // 如果找到对应的扣分信息，更新其属性并返回状态为200 OK，否则返回状态为404 NOT_FOUND
    @PutMapping("/{deductionId}")
    public ResponseEntity<Void> updateDeduction(@PathVariable int deductionId, @RequestBody DeductionInformation updatedDeduction) {
        DeductionInformation existingDeduction = deductionInformationService.getDeductionById(deductionId);
        if (existingDeduction != null) {
            // 更新扣分信息的属性
            existingDeduction.setRemarks(updatedDeduction.getRemarks());
            existingDeduction.setHandler(updatedDeduction.getHandler());
            existingDeduction.setDeductedPoints(updatedDeduction.getDeductedPoints());
            existingDeduction.setDeductionTime(updatedDeduction.getDeductionTime());
            existingDeduction.setApprover(updatedDeduction.getApprover());

            deductionInformationService.updateDeduction(updatedDeduction);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除指定扣分ID的扣分信息
    // 返回状态为204 NO_CONTENT，表示请求已成功处理但没有返回内容
    @DeleteMapping("/{deductionId}")
    public ResponseEntity<Void> deleteDeduction(@PathVariable int deductionId) {
        deductionInformationService.deleteDeduction(deductionId);
        return ResponseEntity.noContent().build();
    }

    // 根据处理人获取扣分信息列表
    // 返回状态为200 OK，包含由处理人处理的扣分信息列表的响应体
    @GetMapping("/handler/{handler}")
    public ResponseEntity<List<DeductionInformation>> getDeductionsByHandler(@PathVariable String handler) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByHandler(handler);
        return ResponseEntity.ok(deductions);
    }

    // 根据时间范围获取扣分信息列表
    // @RequestParam 表示请求参数，这里是指开始时间和结束时间
    // 返回状态为200 OK，包含在指定时间范围内发生的扣分信息列表的响应体
    @GetMapping("/timeRange")
    public ResponseEntity<List<DeductionInformation>> getDeductionsByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<DeductionInformation> deductions = deductionInformationService.getDeductionsByByTimeRange(startTime, endTime);
        return ResponseEntity.ok(deductions);
    }
}
