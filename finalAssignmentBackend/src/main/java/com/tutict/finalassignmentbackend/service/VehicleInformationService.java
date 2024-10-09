package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class VehicleInformationService {

    // 日志记录器，用于记录应用的运行信息
    private static final Logger log = LoggerFactory.getLogger(VehicleInformationService.class);

    // MyBatis映射器，用于执行车辆信息的数据访问操作
    private final VehicleInformationMapper vehicleInformationMapper;
    // Kafka模板，用于发送消息到Kafka消息队列
    private final KafkaTemplate<String, VehicleInformation> kafkaTemplate;

    // 构造函数，通过依赖注入初始化VehicleInformationMapper和KafkaTemplate
    @Autowired
    public VehicleInformationService(VehicleInformationMapper vehicleInformationMapper, KafkaTemplate<String, VehicleInformation> kafkaTemplate) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建车辆信息
    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true, key = "#vehicleInformation.vehicleId")
    public void createVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, VehicleInformation>> future = kafkaTemplate.send("vehicle_create", vehicleInformation);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            vehicleInformationMapper.insert(vehicleInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 根据车辆ID查询车辆信息
    @Cacheable(cacheNames = "vehicleCache", key = "#vehicleId")
    public VehicleInformation getVehicleInformationById(int vehicleId) {
        return vehicleInformationMapper.selectById(vehicleId);
    }

    /**
     * 根据车牌号查询车辆信息
     * @param licensePlate 车牌号
     * @return 车辆信息对象
     * @throws IllegalArgumentException 如果传入的参数为空或空字符串
     */
    @Cacheable(cacheNames = "vehicleCache", key = "#licensePlate")
    public VehicleInformation getVehicleInformationByLicensePlate(String licensePlate) {
        if (licensePlate == null || licensePlate.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid license plate number");
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectOne(queryWrapper);
    }

    // 查询所有车辆信息
    @Cacheable(cacheNames = "vehicleCache")
    public List<VehicleInformation> getAllVehicleInformation() {
        return vehicleInformationMapper.selectList(null);
    }

    /**
     * 根据车辆类型查询车辆信息
     * @param vehicleType 车辆类型
     * @return 车辆信息对象列表
     * @throws IllegalArgumentException 如果传入的参数为空或空字符串
     */
    @Cacheable(cacheNames = "vehicleCache", key = "#vehicleType")
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        if (vehicleType == null || vehicleType.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid vehicle type");
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("vehicle_type", vehicleType);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    /**
     * 根据车主姓名查询车辆信息
     * @param ownerName 车主姓名
     * @return 车辆信息对象列表
     * @throws IllegalArgumentException 如果传入的参数为空或空字符串
     */
    @Cacheable(cacheNames = "vehicleCache", key = "#ownerName")
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        if (ownerName == null || ownerName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid owner name");
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_name", ownerName);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    /**
     * 根据车辆状态查询车辆信息
     * @param currentStatus 车辆状态
     * @return 车辆信息对象列表
     * @throws IllegalArgumentException 如果传入的参数为空或空字符串
     */
    @Cacheable(cacheNames = "vehicleCache", key = "#currentStatus")
    public List<VehicleInformation> getVehicleInformationByStatus(String currentStatus) {
        if (currentStatus == null || currentStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid current status");
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("current_status", currentStatus);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    // 更新车辆信息
    @Transactional
    @CachePut(cacheNames = "vehicleCache", key = "#vehicleInformation.vehicleId")
    public void updateVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, VehicleInformation>> future = kafkaTemplate.send("vehicle_update", vehicleInformation);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            vehicleInformationMapper.updateById(vehicleInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 删除车辆信息
     * @param vehicleId 车辆ID
     */
    @CacheEvict(cacheNames = "vehicleCache", key = "#vehicleId")
    public void deleteVehicleInformation(int vehicleId) {
        try {
            vehicleInformationMapper.deleteById(vehicleId);
        } catch (Exception e) {
            log.error("Exception occurred while deleting vehicle information", e);
        }
    }

    /**
     * 根据车牌号删除车辆信息
     * @param licensePlate 车牌号
     * @throws IllegalArgumentException 如果传入的参数为空或空字符串
     */
    @CacheEvict(cacheNames = "vehicleCache", key = "#licensePlate")
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        if (licensePlate == null || licensePlate.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid license plate number");
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        vehicleInformationMapper.delete(queryWrapper);
    }

    /**
     * 检查车牌号是否存在
     * @param licensePlate 车牌号
     * @return true 如果存在，false 如果不存在
     * @throws IllegalArgumentException 如果传入的参数为空或空字符串
     */
    @Cacheable(cacheNames = "vehicleCache", key = "#licensePlate")
    public boolean isLicensePlateExists(String licensePlate) {
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectCount(queryWrapper) > 0;
    }

}
