package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.service.SysUserService;
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
    public void onSysUserCreateReceived(String message, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processMessage(message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_user_update", groupId = "sysUserGroup", concurrency = "3")
    public void onSysUserUpdateReceived(String message, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processMessage(message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String message, String action) {
        try {
            SysUser entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setUserId(null);
                sysUserService.createSysUser(entity);
            } else if ("update".equals(action)) {
                sysUserService.updateSysUser(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysUser %s action processed successfully", action));
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
