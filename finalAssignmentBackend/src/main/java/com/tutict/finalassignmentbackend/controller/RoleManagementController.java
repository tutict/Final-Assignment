package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.RoleManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/roles")
public class RoleManagementController {

    private final RoleManagementService roleManagementService;

    @Autowired
    public RoleManagementController(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }
}
