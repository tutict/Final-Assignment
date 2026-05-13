package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysUserRole;
import com.tutict.finalassignmentbackend.mapper.SysUserRoleMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
// Kafka 监听器，处理消息
public class SysUserRoleKafkaListener {

    private static final Logger log = Logger.getLogger(SysUserRoleKafkaListener.class.getName());

    private final SysUserRoleMapper sysUserRoleMapper;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public SysUserRoleKafkaListener(SysUserRoleMapper sysUserRoleMapper, ObjectMapper objectMapper) {
        this.sysUserRoleMapper = sysUserRoleMapper;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_user_role_create", groupId = "sysUserRoleGroup", concurrency = "3")
    public void onSysUserRoleCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "sys_user_role_update", groupId = "sysUserRoleGroup", concurrency = "3")
    public void onSysUserRoleUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String message, String action) {
        try {
            SysUserRole entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setId(null);
                sysUserRoleMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysUserRoleMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysUserRole %s action processed successfully", action));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysUserRole message (payload omitted)", action), e);
            throw new RuntimeException(String.format("Failed to process %s SysUserRole message", action), e);
        }
    }
    private SysUserRole deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysUserRole.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message (payload omitted)");
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
