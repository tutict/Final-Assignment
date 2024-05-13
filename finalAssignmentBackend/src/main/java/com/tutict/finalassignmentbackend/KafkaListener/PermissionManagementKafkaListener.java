package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class PermissionManagementKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(PermissionManagementKafkaListener.class);
    private final PermissionManagementService permissionManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public PermissionManagementKafkaListener(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }

    @KafkaListener(topics = "permission_create", groupId = "permission_listener_group")
    public void onPermissionCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为PermissionManagement对象
            PermissionManagement permission = deserializeMessage(message);

            // 根据业务逻辑处理创建权限
            permissionManagementService.createPermission(permission);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create permission message: {}", message, e);
        }
    }

    @KafkaListener(topics = "permission_update", groupId = "permission_listener_group")
    public void onPermissionUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为PermissionManagement对象
            PermissionManagement permission = deserializeMessage(message);

            // 根据业务逻辑处理更新权限
            permissionManagementService.updatePermission(permission);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update permission message: {}", message, e);
        }
    }

    private PermissionManagement deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到PermissionManagement对象的反序列化
        return objectMapper.readValue(message, PermissionManagement.class);
    }
}