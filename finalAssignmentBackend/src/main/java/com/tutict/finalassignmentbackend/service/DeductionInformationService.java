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

    /**
     * 根据ID获取扣款信息
     * @param deductionId 扣款信息ID
     * @return 扣款信息对象
     * @throws IllegalArgumentException 如果deductionId无效
     */
    public DeductionInformation getDeductionById(int deductionId) {
        if (deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID");
        }
        return deductionInformationMapper.selectById(deductionId);
    }

    /**
     * 获取所有扣款信息
     * @return 扣款信息列表
     */
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

    /**
     * 删除扣款信息
     * @param deductionId 扣款信息ID
     */
    public void deleteDeduction(int deductionId) {
        try {
            deductionInformationMapper.deleteById(deductionId);
        } catch (Exception e) {
            log.error("Exception occurred while deleting deduction", e);
        }
    }

    /**
     * 获取指定处理人所有信息
     * @param handler 处理人姓名
     * @return 扣款信息列表
     * @throws IllegalArgumentException 如果处理人姓名为空或无效
     */
    public List<DeductionInformation> getDeductionsByHandler(String handler) {
        if (handler == null || handler.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid handler");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("handler", handler);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    /**
     * 获取指定时间范围内的扣款信息
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 扣款信息列表
     * @throws IllegalArgumentException 如果时间范围无效
     */
    public List<DeductionInformation> getDeductionsByByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deductionTime", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }
}
