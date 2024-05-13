package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.CompletableFuture;

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
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, AppealManagement>> future = kafkaTemplate.send("appeal_create", appeal);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            appealManagementMapper.insert(appeal);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
        //vehicleInformationMapper.insert(vehicleInformation);
        // 发送车辆创建信息到 Kafka 主题
        //kafkaTemplate.send("vehicle_create", vehicleInformation);
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
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, AppealManagement>> future = kafkaTemplate.send("appeal_create", appeal);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            appealManagementMapper.insert(appeal);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
      //  vehicleInformationMapper.updateById(vehicleInformation);
        // 发送车辆更新信息到 Kafka 主题
      //  kafkaTemplate.send("vehicle_update", vehicleInformation);
    }

    // 删除车辆信息
    public void deleteVehicleInformation(int vehicleId) {
        vehicleInformationMapper.deleteById(vehicleId);
    }

    // 根据车牌号删除车辆信息
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        VehicleInformation deletedVehicle = vehicleInformationMapper.selectOne(queryWrapper);
        vehicleInformationMapper.delete(queryWrapper);
    }

    // 检查车牌号是否存在
    public boolean isLicensePlateExists(String licensePlate) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectCount(queryWrapper) > 0;
    }

}
