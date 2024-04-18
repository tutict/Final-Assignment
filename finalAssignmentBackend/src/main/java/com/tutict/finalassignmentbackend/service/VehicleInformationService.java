package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VehicleInformationService {

    private final VehicleInformationMapper vehicleInformationMapper;
    private final KafkaTemplate<String, VehicleInformation> kafkaTemplate;

    @Autowired
    public VehicleInformationService(VehicleInformationMapper vehicleInformationMapper, KafkaTemplate<String, VehicleInformation> kafkaTemplate) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建车辆信息
    public void createVehicleInformation(VehicleInformation vehicleInformation) {
        vehicleInformationMapper.insert(vehicleInformation);
        // 发送车辆创建信息到 Kafka 主题
        kafkaTemplate.send("vehicle_management_topic", vehicleInformation);
    }

    // 根据车辆ID查询车辆信息
    public VehicleInformation getVehicleInformationById(int vehicleId) {
        return vehicleInformationMapper.selectById(vehicleId);
    }

    // 根据车牌号查询车辆信息
    public VehicleInformation getVehicleInformationByLicensePlate(String licensePlate) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectOne(queryWrapper);
    }

    // 查询所有车辆信息
    public List<VehicleInformation> getAllVehicleInformation() {
        return vehicleInformationMapper.selectList(null);
    }

    // 根据车辆类型查询车辆信息
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("vehicle_type", vehicleType);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    // 根据车主姓名查询车辆信息
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_name", ownerName);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    // 根据车辆状态查询车辆信息
    public List<VehicleInformation> getVehicleInformationByStatus(String currentStatus) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("current_status", currentStatus);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    // 更新车辆信息
    public void updateVehicleInformation(VehicleInformation vehicleInformation) {
        vehicleInformationMapper.updateById(vehicleInformation);
        // 发送车辆更新信息到 Kafka 主题
        kafkaTemplate.send("vehicle_management_topic", vehicleInformation);
    }

    // 删除车辆信息
    public void deleteVehicleInformation(int vehicleId) {
        VehicleInformation deletedVehicle = vehicleInformationMapper.selectById(vehicleId);
        vehicleInformationMapper.deleteById(vehicleId);
        // 发送车辆删除信息到 Kafka 主题
        kafkaTemplate.send("vehicle_management_topic", deletedVehicle);
    }

    // 根据车牌号删除车辆信息
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        VehicleInformation deletedVehicle = vehicleInformationMapper.selectOne(queryWrapper);
        vehicleInformationMapper.delete(queryWrapper);
        // 发送车辆删除信息到 Kafka 主题
        kafkaTemplate.send("vehicle_management_topic", deletedVehicle);
    }

    // 检查车牌号是否存在
    public boolean isLicensePlateExists(String licensePlate) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectCount(queryWrapper) > 0;
    }

}
