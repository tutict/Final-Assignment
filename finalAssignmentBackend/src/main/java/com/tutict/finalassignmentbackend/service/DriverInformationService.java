package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.DriverInformationMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DriverInformationService {

    private final DriverInformationMapper driverInformationMapper;
    private final KafkaTemplate<String, DriverInformation> kafkaTemplate;

    @Autowired
    public DriverInformationService(DriverInformationMapper driverInformationMapper, KafkaTemplate<String, DriverInformation> kafkaTemplate) {
        this.driverInformationMapper = driverInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    public void createDriver(DriverInformation driverInformation) {
        // 发送驾驶员信息到 Kafka 主题
        kafkaTemplate.send("driver_create", driverInformation);
        driverInformationMapper.insert(driverInformation);
    }

    public DriverInformation getDriverById(int driverId) {
        return driverInformationMapper.selectById(driverId);
    }

    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    public void updateDriver(DriverInformation driverInformation) {
        kafkaTemplate.send("driver_update", driverInformation);
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
