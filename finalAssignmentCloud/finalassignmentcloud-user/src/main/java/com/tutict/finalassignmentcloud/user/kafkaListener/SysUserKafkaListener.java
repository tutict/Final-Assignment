package com.tutict.finalassignmentcloud.user.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.user.mapper.SysUserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
// Kafka 鐩戝惉鍣紝澶勭悊娑堟伅
public class SysUserKafkaListener {

    private static final Logger log = Logger.getLogger(SysUserKafkaListener.class.getName());

    private final SysUserMapper sysUserMapper;
    private final ObjectMapper objectMapper;

    // 鏋勯€犲櫒娉ㄥ叆渚濊禆
    @Autowired
    public SysUserKafkaListener(SysUserMapper sysUserMapper, ObjectMapper objectMapper) {
        this.sysUserMapper = sysUserMapper;
        this.objectMapper = objectMapper;
    }

    // 鐩戝惉 Kafka 娑堟伅
    @KafkaListener(topics = "sys_user_create", groupId = "sysUserGroup", concurrency = "3")
    public void onSysUserCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    // 鐩戝惉 Kafka 娑堟伅
    @KafkaListener(topics = "sys_user_update", groupId = "sysUserGroup", concurrency = "3")
    public void onSysUserUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        // 使用虚拟线程异步处理，避免阻塞监听线程
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    // 缁熶竴澶勭悊娑堟伅骞舵墽琛屼笟鍔￠€昏緫
    private void processMessage(String message, String action) {
        try {
            SysUser entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setUserId(null);
                sysUserMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysUserMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysUser %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysUser message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysUser message", action), e);
        }
    }

    // 反序列化消息体
    private SysUser deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysUser.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}

