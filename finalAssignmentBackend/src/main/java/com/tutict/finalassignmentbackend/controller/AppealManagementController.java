package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/appeals")
public class AppealManagementController {

    private final AppealManagementService appealManagementService;

    @Autowired
    public AppealManagementController(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    @PostMapping
    public ResponseEntity<Void> createAppeal(@RequestBody AppealManagement appeal) {
        appealManagementService.createAppeal(appeal);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{appealId}")
    public ResponseEntity<AppealManagement> getAppealById(@PathVariable Long appealId) {
        AppealManagement appeal = appealManagementService.getAppealById(appealId);
        if (appeal != null) {
            return ResponseEntity.ok(appeal);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<AppealManagement>> getAllAppeals() {
        List<AppealManagement> appeals = appealManagementService.getAllAppeals();
        return ResponseEntity.ok(appeals);
    }

    @PutMapping("/{appealId}")
    public ResponseEntity<Void> updateAppeal(@PathVariable Long appealId, @RequestBody AppealManagement updatedAppeal) {
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
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{appealId}")
    public ResponseEntity<Void> deleteAppeal(@PathVariable Long appealId) {
        appealManagementService.deleteAppeal(appealId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/status/{processStatus}")
    public ResponseEntity<List<AppealManagement>> getAppealsByProcessStatus(@PathVariable String processStatus) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
        return ResponseEntity.ok(appeals);
    }

    @GetMapping("/name/{appealName}")
    public ResponseEntity<List<AppealManagement>> getAppealsByAppealName(@PathVariable String appealName) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByAppealName(appealName);
        return ResponseEntity.ok(appeals);
    }

    @GetMapping("/{appealId}/offense")
    public ResponseEntity<OffenseInformation> getOffenseByAppealId(@PathVariable Long appealId) {
        OffenseInformation offense = appealManagementService.getOffenseByAppealId(appealId);
        if (offense != null) {
            return ResponseEntity.ok(offense);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}