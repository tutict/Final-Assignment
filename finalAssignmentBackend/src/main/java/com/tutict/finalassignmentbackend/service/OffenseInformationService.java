package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;

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

    // 创建违规信息，包含Kafka消息的异步发送和数据库插入操作
    @Transactional
    public void createOffense(OffenseInformation offenseInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, OffenseInformation>> future = kafkaTemplate.send("offense_create", offenseInformation);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            offenseInformationMapper.insert(offenseInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 根据违规ID获取违规信息
    public OffenseInformation getOffenseByOffenseId(int offenseId) {
        return offenseInformationMapper.selectById(offenseId);
    }

    // 获取所有违规信息
    public List<OffenseInformation> getOffensesInformation() {
        return offenseInformationMapper.selectList(null);
    }

    // 更新违规信息，包含Kafka消息的异步发送和数据库更新操作
    @Transactional
    public void updateOffense(OffenseInformation offenseInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, OffenseInformation>> future = kafkaTemplate.send("offense_update", offenseInformation);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            offenseInformationMapper.updateById(offenseInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 删除违规信息
     * @param offenseId 违规ID
     */
    public void deleteOffense(int offenseId) {
        try {
            if (offenseId <= 0) {
                throw new IllegalArgumentException("Invalid offense ID");
            }
            offenseInformationMapper.deleteById(offenseId);
        } catch (Exception e) {
            log.error("Exception occurred while deleting offense", e);
        }
    }

    /**
     * 根据时间范围查询违规信息
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 违规信息列表
     * @throws IllegalArgumentException 如果提供的时间范围无效，则抛出此异常
     */
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
    public List<OffenseInformation> getOffensesByLicensePlate(String offenseLicensePlate) {
        if (offenseLicensePlate == null || offenseLicensePlate.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid license plate");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", offenseLicensePlate);
        return offenseInformationMapper.selectList(queryWrapper);
    }
}
