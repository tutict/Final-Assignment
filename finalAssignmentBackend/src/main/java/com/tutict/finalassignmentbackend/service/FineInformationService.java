package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.FineInformationMapper;
import com.tutict.finalassignmentbackend.entity.FineInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class FineInformationService {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(FineInformationService.class);

    private final FineInformationMapper fineInformationMapper;
    private final KafkaTemplate<String, FineInformation> kafkaTemplate;

    @Autowired
    public FineInformationService(FineInformationMapper fineInformationMapper, KafkaTemplate<String, FineInformation> kafkaTemplate) {
        this.fineInformationMapper = fineInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    public void createFine(FineInformation fineInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, FineInformation>> future =kafkaTemplate.send("fine_create", fineInformation);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            fineInformationMapper.insert(fineInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public FineInformation getFineById(int fineId) {
        return fineInformationMapper.selectById(fineId);
    }

    public List<FineInformation> getAllFines() {
        return fineInformationMapper.selectList(null);
    }

    @Transactional
    public void updateFine(FineInformation fineInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, FineInformation>> future =kafkaTemplate.send("fine_update", fineInformation);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            fineInformationMapper.updateById(fineInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public void deleteFine(int fineId) {
        fineInformationMapper.deleteById(fineId);
    }

    // get all fines by payee
    public List<FineInformation> getFinesByPayee(String payee) {
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("payee", payee);
        return fineInformationMapper.selectList(queryWrapper);
    }

    // get all fines by time range
    public List<FineInformation> getFinesByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("fineTime", startTime, endTime);
        return fineInformationMapper.selectList(queryWrapper);
    }

    public FineInformation getFineByReceiptNumber(String receiptNumber) {
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("receiptNumber", receiptNumber);
        return fineInformationMapper.selectOne(queryWrapper);
    }
}
