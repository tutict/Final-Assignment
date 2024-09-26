package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.AppealManagementMapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.CompletableFuture;

// 申诉管理服务类
@Service
public class AppealManagementService {

    // 日志记录器
    private static final Logger log = LoggerFactory.getLogger(AppealManagementService.class);

    // 持久层映射器，用于申诉管理操作
    private final AppealManagementMapper appealManagementMapper;
    // 持久层映射器，用于违法行为信息操作
    private final OffenseInformationMapper offenseInformationMapper;
    // Kafka模板，用于发送申诉相关消息
    private final KafkaTemplate<String, AppealManagement> kafkaTemplate;

    // 构造函数，通过DI注入映射器和Kafka模板
    @Autowired
    public AppealManagementService(AppealManagementMapper appealManagementMapper, OffenseInformationMapper offenseInformationMapper, KafkaTemplate<String, AppealManagement> kafkaTemplate) {
        this.appealManagementMapper = appealManagementMapper;
        this.offenseInformationMapper = offenseInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建申诉记录
    @Transactional
    public void createAppeal(AppealManagement appeal) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, AppealManagement>> future = kafkaTemplate.send("appeal_create", appeal);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
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
    }

    /**
     * 根据申诉ID获取申诉记录
     * @param appealId 申诉ID
     * @return 申诉记录
     */
    public AppealManagement getAppealById(Long appealId) {
        return appealManagementMapper.selectById(appealId);
    }

    /**
     * 获取所有申诉记录
     * @return 所有申诉记录列表
     */
    public List<AppealManagement> getAllAppeals() {
        return appealManagementMapper.selectList(null);
    }

    // 更新申诉记录
    @Transactional
    public void updateAppeal(AppealManagement appeal) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, AppealManagement>> future = kafkaTemplate.send("appeal_updated", appeal);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            appealManagementMapper.updateById(appeal);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }


    /**
     * 删除申诉记录
     * @param appealId 申诉ID
     */
    public void deleteAppeal(Long appealId) {
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal == null) {
            log.warn("Appeal with ID {} not found, cannot delete", appealId);
            return;
        }

        int result = appealManagementMapper.deleteById(appealId);
        if (result > 0) {
            log.info("Appeal with ID {} deleted successfully", appealId);
        } else {
            log.error("Failed to delete appeal with ID {}", appealId);
        }
    }


    /**
     * 根据申诉状态查询申诉信息
     * @param processStatus 申诉状态
     * @return 申诉信息列表
     */
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectList(queryWrapper);
    }

    /**
     * 根据申诉人姓名查询申诉信息
     * @param appealName 申诉人姓名
     * @return 申诉信息列表
     */
    public List<AppealManagement> getAppealsByAppealName(String appealName) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("appeal_name", appealName);
        return appealManagementMapper.selectList(queryWrapper);
    }

    /**
     * 根据申诉ID查询关联的违法行为信息
     * @param appealId 申诉ID
     * @return 关联的违法行为信息
     */
    public OffenseInformation getOffenseByAppealId(Long appealId) {
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal != null) {
            return offenseInformationMapper.selectById(appeal.getOffenseId());
        } else {
            log.warn("No appeal found with ID: {}", appealId);
            return null;
        }
    }
}
