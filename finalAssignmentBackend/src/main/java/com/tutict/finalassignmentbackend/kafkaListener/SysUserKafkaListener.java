package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.service.SysUserService;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
// Kafka 监听器，处理消息
public class SysUserKafkaListener {

    private static final Logger log = Logger.getLogger(SysUserKafkaListener.class.getName());

    private final SysUserService sysUserService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysUserKafkaListener(SysUserService sysUserService, ObjectMapper objectMapper) {
        this.sysUserService = sysUserService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_user_create", groupId = "sysUserGroup", concurrency = "3")
    public void onSysUserCreateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processRecord(record, "create", ack);
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_user_update", groupId = "sysUserGroup", concurrency = "3")
    public void onSysUserUpdateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processRecord(record, "update", ack);
    }

    private void processRecord(ConsumerRecord<String, String> record, String action, Acknowledgment ack) {
        String idempotencyKey = record.key();
        if (idempotencyKey != null && sysUserService.shouldSkipProcessing(idempotencyKey)) {
            log.log(Level.INFO, "Skipping duplicate SysUser message: key={0}", idempotencyKey);
            ack.acknowledge();
            return;
        }
        try {
            SysUser entity = processMessage(record.value(), action);
            if (idempotencyKey != null) {
                sysUserService.markHistorySuccess(idempotencyKey, entity.getUserId());
            }
            ack.acknowledge();
        } catch (Exception e) {
            if (idempotencyKey != null) {
                sysUserService.markHistoryFailure(idempotencyKey, e.getMessage());
            }
            log.log(Level.SEVERE, "SysUser message processing failed", e);
            throw e;
        }
    }

    // 统一处理消息并执行业务逻辑
    private SysUser processMessage(String message, String action) {
        try {
            SysUser entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setUserId(null);
                entity = sysUserService.createSysUser(entity);
            } else if ("update".equals(action)) {
                entity = sysUserService.updateSysUser(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return entity;
            }
            log.info(String.format("SysUser %s action processed successfully", action));
            return entity;
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysUser message (payload omitted)", action), e);
            throw new RuntimeException(String.format("Failed to process %s SysUser message", action), e);
        }
    }
    private SysUser deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysUser.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message (payload omitted)");
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
