package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
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

import java.util.Date;
import java.util.List;

// 定义一个服务类，用于处理违规信息的相关操作
@Service
public class OffenseInformationService {

    // Logger用于记录应用运行时的日志信息
    private static final Logger log = LoggerFactory.getLogger(OffenseInformationService.class);

    // 定义一个违规信息的Mapper接口实例，用于数据库操作
    private final OffenseInformationMapper offenseInformationMapper;
    // 定义一个Kafka模板实例，用于发送消息到Kafka
    private final KafkaTemplate<String, OffenseInformation> kafkaTemplate;

    // 构造函数，通过Spring的依赖注入初始化Mapper和KafkaTemplate实例
    @Autowired
    public OffenseInformationService(OffenseInformationMapper offenseInformationMapper, KafkaTemplate<String, OffenseInformation> kafkaTemplate) {
        this.offenseInformationMapper = offenseInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建违规信息，包含Kafka消息的同步发送和数据库插入操作
    @Transactional
    @CacheEvict(value = "offenseCache", key = "#offenseInformation.offenseId")
    public void createOffense(OffenseInformation offenseInformation) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("offense_create", offenseInformation);
            // 数据库插入
            offenseInformationMapper.insert(offenseInformation);
        } catch (Exception e) {
            log.error("Exception occurred while creating offense or sending Kafka message", e);
            throw new RuntimeException("Failed to create offense", e);
        }
    }

    // 根据违规ID获取违规信息
    @Cacheable(value = "offenseCache", key = "#offenseId")
    public OffenseInformation getOffenseByOffenseId(int offenseId) {
        return offenseInformationMapper.selectById(offenseId);
    }

    // 获取所有违规信息
    @Cacheable(value = "offenseCache", key = "'allOffenses'" )
    public List<OffenseInformation> getOffensesInformation() {
        return offenseInformationMapper.selectList(null);
    }

    // 更新违规信息，包含Kafka消息的同步发送和数据库更新操作
    @Transactional
    @CachePut(value = "offenseCache", key = "#offenseInformation.offenseId")
    public void updateOffense(OffenseInformation offenseInformation) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("offense_update", offenseInformation);
            // 更新数据库记录
            offenseInformationMapper.updateById(offenseInformation);
        } catch (Exception e) {
            log.error("Exception occurred while updating offense or sending Kafka message", e);
            throw new RuntimeException("Failed to update offense", e);
        }
    }

    /**
     * 删除违规信息
     * @param offenseId 违规ID
     */
    @Transactional
    @CacheEvict(value = "offenseCache", key = "#offenseId")
    public void deleteOffense(int offenseId) {
        try {
            if (offenseId <= 0) {
                throw new IllegalArgumentException("Invalid offense ID");
            }
            int result = offenseInformationMapper.deleteById(offenseId);
            if (result > 0) {
                log.info("Offense with ID {} deleted successfully", offenseId);
            } else {
                log.error("Failed to delete offense with ID {}", offenseId);
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting offense", e);
            throw new RuntimeException("Failed to delete offense", e);
        }
    }

    /**
     * 根据时间范围查询违规信息
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 违规信息列表
     * @throws IllegalArgumentException 如果提供的时间范围无效，则抛出此异常
     */
    @Cacheable(value = "offenseCache", key = "#root.methodName + '_' + #startTime + '-' + #endTime")
    public List<OffenseInformation> getOffensesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("offense_time", startTime, endTime);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    /**
     * 根据处理状态查询违规信息
     * @param processState 处理状态
     * @return 违规信息列表
     * @throws IllegalArgumentException 如果提供的处理状态无效，则抛出此异常
     */
    @Cacheable(value = "offenseCache", key = "#root.methodName + '_' + #processState")
    public List<OffenseInformation> getOffensesByProcessState(String processState) {
        if (processState == null || processState.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid process state");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processState);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    /**
     * 根据驾驶员姓名查询违规信息
     * @param driverName 驾驶员姓名
     * @return 违规信息列表
     * @throws IllegalArgumentException 如果提供的驾驶员姓名无效，则抛出此异常
     */
    @Cacheable(value = "offenseCache", key = "#root.methodName + '_' + #driverName")
    public List<OffenseInformation> getOffensesByDriverName(String driverName) {
        if (driverName == null || driverName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid driver name");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_name", driverName);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    /**
     * 根据车牌号查询违规信息
     * @param offenseLicensePlate 车牌号
     * @return 违规信息列表
     * @throws IllegalArgumentException 如果提供的车牌号无效，则抛出此异常
     */
    @Cacheable(value = "offenseCache", key = "#root.methodName + '_' + #offenseLicensePlate")
    public List<OffenseInformation> getOffensesByLicensePlate(String offenseLicensePlate) {
        if (offenseLicensePlate == null || offenseLicensePlate.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid license plate");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", offenseLicensePlate);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, OffenseInformation offenseInformation) throws Exception {
        SendResult<String, OffenseInformation> sendResult = kafkaTemplate.send(topic, offenseInformation).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}
