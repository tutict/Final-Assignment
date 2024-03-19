package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.DriverInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/drivers")
public class DriverInformationController {

    private final DriverInformationService driverInformationService;

    @Autowired
    public DriverInformationController(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }
}
