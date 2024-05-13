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

@Service
public class AppealManagementService {

    private static final Logger log = LoggerFactory.getLogger(AppealManagementService.class);

    private final AppealManagementMapper appealManagementMapper;
    private final OffenseInformationMapper offenseInformationMapper;
    private final KafkaTemplate<String, AppealManagement> kafkaTemplate;

    @Autowired
    public AppealManagementService(AppealManagementMapper appealManagementMapper, OffenseInformationMapper offenseInformationMapper, KafkaTemplate<String, AppealManagement> kafkaTemplate) {
        this.appealManagementMapper = appealManagementMapper;
        this.offenseInformationMapper = offenseInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

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

    public AppealManagement getAppealById(Long appealId) {
        return appealManagementMapper.selectById(appealId);
    }

    public List<AppealManagement> getAllAppeals() {
        return appealManagementMapper.selectList(null);
    }

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


    public void deleteAppeal(Long appealId) {
        appealManagementMapper.deleteById(appealId);
    }

    //根据申述状态查询申述信息
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectList(queryWrapper);
    }

    //根据申述人姓名查询申述信息
    public List<AppealManagement> getAppealsByAppealName(String appealName) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("appeal_name", appealName);
        return appealManagementMapper.selectList(queryWrapper);
    }

    //根据申述ID查询关联的违法行为信息
    public OffenseInformation getOffenseByAppealId(Long appealId) {
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal != null) {
            return offenseInformationMapper.selectById(appeal.getOffenseId());
        }
        return null;
    }
}
