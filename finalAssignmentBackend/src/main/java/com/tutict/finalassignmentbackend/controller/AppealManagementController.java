package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.AppealManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/appeals")
public class AppealManagementController {

    private final AppealManagementService appealManagementService;

    @Autowired
    public AppealManagementController(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }
}
