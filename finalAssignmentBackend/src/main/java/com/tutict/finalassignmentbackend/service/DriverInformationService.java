package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.DriverInformationMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
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
     * 同步发送司机创建消息到 Kafka 并将司机信息插入数据库。
     * @param driverInformation 包含司机详细信息的 DriverInformation 对象
     */
    @Transactional
    @CacheEvict(value = "driverCache", key = "#driverInformation.driverId")
    public void createDriver(DriverInformation driverInformation) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("driver_create", driverInformation);
            // 数据库插入
            driverInformationMapper.insert(driverInformation);
        } catch (Exception e) {
            log.error("Exception occurred while creating driver or sending Kafka message", e);
            throw new RuntimeException("Failed to create driver", e);
        }
    }

    /**
     * 根据司机 ID 获取司机信息。
     * @param driverId 司机的 ID
     * @return 对应于司机 ID 的 DriverInformation 对象
     */
    @Cacheable(value = "driverCache", key = "#driverId")
    public DriverInformation getDriverById(int driverId) {
        return driverInformationMapper.selectById(driverId);
    }

    /**
     * 获取所有司机信息。
     * @return 所有 DriverInformation 对象的列表
     */
    @Cacheable(value = "driverCache", key = "'allDrivers'")
    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    /**
     * 同步发送司机更新消息到 Kafka 并更新数据库中的司机信息。
     * @param driverInformation 包含更新后的司机详细信息的 DriverInformation 对象
     */
    @Transactional
    @CachePut(value = "driverCache", key = "#driverInformation.driverId")
    public void updateDriver(DriverInformation driverInformation) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("driver_update", driverInformation);
            // 更新数据库记录
            driverInformationMapper.updateById(driverInformation);
        } catch (Exception e) {
            log.error("Exception occurred while updating driver or sending Kafka message", e);
            throw new RuntimeException("Failed to update driver", e);
        }
    }

    /**
     * 根据司机 ID 删除司机信息。
     * @param driverId 要删除的司机的 ID
     */
    @Transactional
    @CacheEvict(value = "driverCache", key = "#driverId")
    public void deleteDriver(int driverId) {
        try {
            int result = driverInformationMapper.deleteById(driverId);
            if (result > 0) {
                log.info("Driver with ID {} deleted successfully", driverId);
            } else {
                log.error("Failed to delete driver with ID {}", driverId);
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting driver", e);
            throw new RuntimeException("Failed to delete driver", e);
        }
    }

    /**
     * 根据身份证号码获取司机信息。
     * @param idCardNumber 司机的身份证号码
     * @return 对应于身份证号码的 DriverInformation 对象列表
     */
    @Cacheable(value = "driverCache", key = "#root.methodName + '_' + #idCardNumber")
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
    @Cacheable(value = "driverCache", key = "#root.methodName + '_' + #driverLicenseNumber")
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
    @Cacheable(value = "driverCache", key = "#root.methodName + '_' + #name")
    public List<DriverInformation> getDriversByName(String name) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", name);
        return driverInformationMapper.selectList(queryWrapper);
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, DriverInformation driverInformation) throws Exception {
        SendResult<String, DriverInformation> sendResult = kafkaTemplate.send(topic, driverInformation).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}
