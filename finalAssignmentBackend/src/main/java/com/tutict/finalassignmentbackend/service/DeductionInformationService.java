package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.DeductionInformationMapper;
import com.tutict.finalassignmentbackend.entity.DeductionInformation;
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

@Service
public class DeductionInformationService {

    // Logger用于记录日志信息
    private static final Logger log = LoggerFactory.getLogger(DeductionInformationService.class);


    // Mapper用于数据库操作
    private final DeductionInformationMapper deductionInformationMapper;
    // KafkaTemplate用于发送Kafka消息
    private final KafkaTemplate<String, DeductionInformation> kafkaTemplate;

    // 构造函数，通过@Autowired自动装配依赖项
    @Autowired
    public DeductionInformationService(DeductionInformationMapper deductionInformationMapper, KafkaTemplate<String, DeductionInformation> kafkaTemplate) {
        this.deductionInformationMapper = deductionInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建扣款信息，使用@Transactional确保事务一致性
    @Transactional
    public void createDeduction(DeductionInformation deduction) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, DeductionInformation>> future =  kafkaTemplate.send("deduction_create", deduction);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            deductionInformationMapper.insert(deduction);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 根据ID获取扣款信息
    public DeductionInformation getDeductionById(int deductionId) {
        return deductionInformationMapper.selectById(deductionId);
    }

    // 获取所有扣款信息
    public List<DeductionInformation> getAllDeductions() {
        return deductionInformationMapper.selectList(null);
    }

    // 更新扣款信息，使用@Transactional确保事务一致性
    @Transactional
    public void updateDeduction(DeductionInformation deduction) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, DeductionInformation>> future =kafkaTemplate.send("deduction_update", deduction);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            deductionInformationMapper.updateById(deduction);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 删除扣款信息
    public void deleteDeduction(int deductionId) {
        deductionInformationMapper.deleteById(deductionId);
    }

    // 获取指定处理人所有信息
    public List<DeductionInformation> getDeductionsByHandler(String handler) {
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("handler", handler);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    // 获取指定时间范围内的所有信息
    public List<DeductionInformation> getDeductionsByByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deductionTime", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }
}
