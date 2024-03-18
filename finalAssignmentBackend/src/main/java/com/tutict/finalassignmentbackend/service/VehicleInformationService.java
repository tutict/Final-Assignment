package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.VehicleInformationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class VehicleInformationService {

    private final VehicleInformationMapper vehicleInformationMapper;

    @Autowired
    public VehicleInformationService(VehicleInformationMapper vehicleInformationMapper) {
        this.vehicleInformationMapper = vehicleInformationMapper;
    }
}
