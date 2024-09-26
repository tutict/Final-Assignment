package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.DriverInformationMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class DriverInformationService {

    // 日志记录器实例
    private static final Logger log = LoggerFactory.getLogger(DriverInformationService.class);

    // 用于操作司机信息的数据映射器
    private final DriverInformationMapper driverInformationMapper;
    // 发送司机信息对象到 Kafka 的模板
    private final KafkaTemplate<String, DriverInformation> kafkaTemplate;

    // 依赖注入构造函数
    @Autowired
    public DriverInformationService(DriverInformationMapper driverInformationMapper, KafkaTemplate<String, DriverInformation> kafkaTemplate) {
        this.driverInformationMapper = driverInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * 异步发送司机创建消息到 Kafka 并将司机信息插入数据库。
     * @param driverInformation 包含司机详细信息的 DriverInformation 对象
     */
    @Transactional
    public void createDriver(DriverInformation driverInformation) {
        try {
            // 异步发送消息到 Kafka 并处理发送结果
            CompletableFuture<SendResult<String, DriverInformation>> future = kafkaTemplate.send("driver_create", driverInformation);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("创建消息已成功发送到 Kafka: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("发送消息到 Kafka 失败，触发事务回滚", ex);
                // 抛出异常
                throw new RuntimeException("Kafka 消息发送失败", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring 事务管理器将处理事务
            driverInformationMapper.insert(driverInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("更新请求或发送 Kafka 消息时发生异常", e);
            // 异常将由 Spring 事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 根据司机 ID 获取司机信息。
     * @param driverId 司机的 ID
     * @return 对应于司机 ID 的 DriverInformation 对象
     */
    public DriverInformation getDriverById(int driverId) {
        return driverInformationMapper.selectById(driverId);
    }

    /**
     * 获取所有司机信息。
     * @return 所有 DriverInformation 对象的列表
     */
    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    /**
     * 异步发送司机更新消息到 Kafka 并更新数据库中的司机信息。
     * @param driverInformation 包含更新后的司机详细信息的 DriverInformation 对象
     */
    @Transactional
    public void updateDriver(DriverInformation driverInformation) {
        try {
            // 异步发送消息到 Kafka 并处理发送结果
            CompletableFuture<SendResult<String, DriverInformation>> future = kafkaTemplate.send("driver_update", driverInformation);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("更新消息已成功发送到 Kafka: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("发送消息到 Kafka 失败，触发事务回滚", ex);
                // 抛出异常
                throw new RuntimeException("Kafka 消息发送失败", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring 事务管理器将处理事务
            driverInformationMapper.updateById(driverInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("更新请求或发送 Kafka 消息时发生异常", e);
            // 异常将由 Spring 事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 根据司机 ID 删除司机信息。
     * @param driverId 要删除的司机的 ID
     */
    public void deleteDriver(int driverId) {
        driverInformationMapper.deleteById(driverId);
    }

    /**
     * 根据身份证号码获取司机信息。
     * @param idCardNumber 司机的身份证号码
     * @return 对应于身份证号码的 DriverInformation 对象列表
     */
    public List<DriverInformation> getDriversByIdCardNumber(String idCardNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        return driverInformationMapper.selectList(queryWrapper);
    }

    /**
     * 根据驾驶证号码获取司机信息。
     * @param driverLicenseNumber 司机的驾驶证号码
     * @return 对应于驾驶证号码的 DriverInformation 对象
     */
    public DriverInformation getDriverByDriverLicenseNumber(String driverLicenseNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_license_number", driverLicenseNumber);
        return driverInformationMapper.selectOne(queryWrapper);
    }

    /**
     * 根据姓名获取司机信息。
     * @param name 司机的姓名
     * @return 姓名包含指定名称的所有 DriverInformation 对象列表
     */
    public List<DriverInformation> getDriversByName(String name) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", name);
        return driverInformationMapper.selectList(queryWrapper);
    }
}
