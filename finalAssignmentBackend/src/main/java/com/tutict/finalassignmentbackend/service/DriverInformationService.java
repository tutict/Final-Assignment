package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.dao.DriverInformationMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DriverInformationService {

    private final DriverInformationMapper driverInformationMapper;

    @Autowired
    public DriverInformationService(DriverInformationMapper driverInformationMapper) {
        this.driverInformationMapper = driverInformationMapper;
    }

    public void createDriver(DriverInformation driverInformation) {
        driverInformationMapper.insert(driverInformation);
    }

    public DriverInformation getDriverById(int driverId) {
        return driverInformationMapper.selectById(driverId);
    }

    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    public void updateDriver(DriverInformation driverInformation) {
        driverInformationMapper.updateById(driverInformation);
    }

    public void deleteDriver(int driverId) {
        driverInformationMapper.deleteById(driverId);
    }

    // get driver by id card number
    public List<DriverInformation> getDriversByIdCardNumber(String idCardNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        return driverInformationMapper.selectList(queryWrapper);
    }

    // get driver by driver license number
    public DriverInformation getDriverByDriverLicenseNumber(String driverLicenseNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_license_number", driverLicenseNumber);
        return driverInformationMapper.selectOne(queryWrapper);
    }

    // get driver by name
    public List<DriverInformation> getDriversByName(String Name) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", Name);
        return driverInformationMapper.selectList(queryWrapper);
    }
}

