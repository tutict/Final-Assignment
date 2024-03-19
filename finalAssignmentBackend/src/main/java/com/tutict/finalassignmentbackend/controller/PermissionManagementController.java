package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/permissions")
public class PermissionManagementController {

    private final PermissionManagementService permissionManagementService;

    @Autowired
    public PermissionManagementController(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }
}
