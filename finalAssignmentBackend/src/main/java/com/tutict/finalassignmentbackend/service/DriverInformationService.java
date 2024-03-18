package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.DriverInformationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class DriverInformationService {

    private final DriverInformationMapper driverInformationMapper;

    @Autowired
    public DriverInformationService(DriverInformationMapper driverInformationMapper) {
        this.driverInformationMapper = driverInformationMapper;
    }
}
