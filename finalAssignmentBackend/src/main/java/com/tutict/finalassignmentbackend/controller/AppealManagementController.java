package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.concurrent.CompletableFuture;

// 标记为 REST 控制器，并设置基础路径和内容类型
@RestController
@RequestMapping("/api/appeals")
@Slf4j
public class AppealManagementController {

    private final AppealManagementService appealManagementService;

    @Autowired
    public AppealManagementController(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    // 创建新的申诉
    // [POST] 请求，创建并存储新的申诉信息
    @PostMapping
    @Async("virtualThreadExecutor") // 使用虚拟线程执行器
    public CompletableFuture<ResponseEntity<Void>> createAppeal(@RequestBody AppealManagement appeal) {
        appealManagementService.createAppeal(appeal);
        return CompletableFuture.completedFuture(ResponseEntity.status(HttpStatus.CREATED).build());
    }

    // 根据ID获取申诉
    // [GET] 请求，通过申诉ID检索申诉信息
    @GetMapping("/{appealId}")
    @Async("virtualThreadExecutor")
    public CompletableFuture<ResponseEntity<AppealManagement>> getAppealById(@PathVariable Integer appealId) {
        AppealManagement appeal = appealManagementService.getAppealById(appealId);
        if (appeal != null) {
            return CompletableFuture.completedFuture(ResponseEntity.ok(appeal));
        } else {
            return CompletableFuture.completedFuture(ResponseEntity.status(HttpStatus.NOT_FOUND).build());
        }
    }

    // 获取所有申诉
    // [GET] 请求，检索并返回所有申诉的列表
    @GetMapping
    @Async("virtualThreadExecutor")
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAllAppeals() {
        List<AppealManagement> appeals = appealManagementService.getAllAppeals();
        return CompletableFuture.completedFuture(ResponseEntity.ok(appeals));
    }

    // 更新申诉信息
    // [PUT] 请求，根据ID检索并更新现有申诉的信息
    @PutMapping("/{appealId}")
    @Async("virtualThreadExecutor")
    public CompletableFuture<ResponseEntity<Void>> updateAppeal(@PathVariable Integer appealId, @RequestBody AppealManagement updatedAppeal) {
        AppealManagement existingAppeal = appealManagementService.getAppealById(appealId);
        if (existingAppeal != null) {
            // 更新现有申诉的属性
            existingAppeal.setOffenseId(updatedAppeal.getOffenseId());
            existingAppeal.setAppellantName(updatedAppeal.getAppellantName());
            existingAppeal.setIdCardNumber(updatedAppeal.getIdCardNumber());
            existingAppeal.setContactNumber(updatedAppeal.getContactNumber());
            existingAppeal.setAppealReason(updatedAppeal.getAppealReason());
            existingAppeal.setAppealTime(updatedAppeal.getAppealTime());
            existingAppeal.setProcessStatus(updatedAppeal.getProcessStatus());
            existingAppeal.setProcessResult(updatedAppeal.getProcessResult());

            // 更新申诉
            appealManagementService.updateAppeal(existingAppeal);
            return CompletableFuture.completedFuture(ResponseEntity.ok().build());
        } else {
            return CompletableFuture.completedFuture(ResponseEntity.status(HttpStatus.NOT_FOUND).build());
        }
    }

    // 删除申诉
    // [DELETE] 请求，根据ID删除申诉信息
    @DeleteMapping("/{appealId}")
    @Async("virtualThreadExecutor")
    public CompletableFuture<ResponseEntity<Void>> deleteAppeal(@PathVariable Integer appealId) {
        appealManagementService.deleteAppeal(appealId);
        return CompletableFuture.completedFuture(ResponseEntity.noContent().build());
    }

    // 根据处理状态获取申诉
    // [GET] 请求，通过处理状态检索申诉列表
    @GetMapping("/status/{processStatus}")
    @Async("virtualThreadExecutor")
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAppealsByProcessStatus(@PathVariable String processStatus) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
        return CompletableFuture.completedFuture(ResponseEntity.ok(appeals));
    }

    // 根据申诉人姓名获取申诉
    // [GET] 请求，通过申诉人姓名检索申诉列表
    @GetMapping("/name/{appealName}")
    @Async("virtualThreadExecutor")
    public CompletableFuture<ResponseEntity<List<AppealManagement>>> getAppealsByAppealName(@PathVariable String appealName) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByAppealName(appealName);
        return CompletableFuture.completedFuture(ResponseEntity.ok(appeals));
    }

    // 根据申诉ID获取违规信息
    // [GET] 请求，通过申诉ID检索关联的违规信息
    @GetMapping("/{appealId}/offense")
    @Async("virtualThreadExecutor")
    public CompletableFuture<ResponseEntity<OffenseInformation>> getOffenseByAppealId(@PathVariable Integer appealId) {
        OffenseInformation offense = appealManagementService.getOffenseByAppealId(appealId);
        if (offense != null) {
            return CompletableFuture.completedFuture(ResponseEntity.ok(offense));
        } else {
            return CompletableFuture.completedFuture(ResponseEntity.status(HttpStatus.NOT_FOUND).build());
        }
    }
}
