package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/vehicles")
public class VehicleInformationController {

    private final VehicleInformationService vehicleInformationService;

    @Autowired
    public VehicleInformationController(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }
}

