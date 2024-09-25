package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
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

// 控制器类，用于处理与罚款信息相关的HTTP请求
@RestController
@RequestMapping("/eventbus/fines")
public class FineInformationController {

    // 罚款信息服务的接口实例，用于操作罚款信息数据
    private final FineInformationService fineInformationService;

    // 构造函数，通过依赖注入初始化罚款信息服务实例
    @Autowired
    public FineInformationController(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    // 创建新的罚款信息记录
    // 请求体中的罚款信息将被传递给服务层的createFine方法处理
    @PostMapping
    public ResponseEntity<Void> createFine(@RequestBody FineInformation fineInformation) {
        fineInformationService.createFine(fineInformation);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据罚款ID获取罚款信息
    // 如果找到对应的罚款信息，则返回200状态码和罚款信息；否则返回404状态码
    @GetMapping("/{fineId}")
    public ResponseEntity<FineInformation> getFineById(@PathVariable int fineId) {
        FineInformation fineInformation = fineInformationService.getFineById(fineId);
        if (fineInformation != null) {
            return ResponseEntity.ok(fineInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有罚款信息记录
    // 返回200状态码和所有罚款信息的列表
    @GetMapping
    public ResponseEntity<List<FineInformation>> getAllFines() {
        List<FineInformation> fines = fineInformationService.getAllFines();
        return ResponseEntity.ok(fines);
    }

    // 更新指定罚款ID的罚款信息
    // 如果找到对应的罚款信息，则更新其信息并返回200状态码；否则返回404状态码
    @PutMapping("/{fineId}")
    public ResponseEntity<Void> updateFine(@PathVariable int fineId, @RequestBody FineInformation updatedFineInformation) {
        FineInformation existingFineInformation = fineInformationService.getFineById(fineId);
        if (existingFineInformation != null) {

            // 更新罚款信息的各个字段
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

    // 删除指定罚款ID的罚款信息记录
    // 删除后返回204状态码
    @DeleteMapping("/{fineId}")
    public ResponseEntity<Void> deleteFine(@PathVariable int fineId) {
        fineInformationService.deleteFine(fineId);
        return ResponseEntity.noContent().build();
    }

    // 根据受款人名称获取罚款信息列表
    // 如果找到相关罚款信息，则返回200状态码和罚款信息列表；否则返回空列表
    @GetMapping("/payee/{payee}")
    public ResponseEntity<List<FineInformation>> getFinesByPayee(@PathVariable String payee) {
        List<FineInformation> fines = fineInformationService.getFinesByPayee(payee);
        return ResponseEntity.ok(fines);
    }

    // 根据时间范围获取罚款信息列表
    // 通过请求参数中的开始时间和结束时间筛选罚款信息，并返回200状态码和筛选结果
    @GetMapping("/timeRange")
    public ResponseEntity<List<FineInformation>> getFinesByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<FineInformation> fines = fineInformationService.getFinesByTimeRange(startTime, endTime);
        return ResponseEntity.ok(fines);
    }

    // 根据收据编号获取罚款信息
    // 如果找到对应的罚款信息，则返回200状态码和罚款信息；否则返回404状态码
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
