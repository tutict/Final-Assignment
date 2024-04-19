package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.service.RoleManagementService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class RoleManagementKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(RoleManagementKafkaListener.class);
    private final RoleManagementService roleManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public RoleManagementKafkaListener(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }

    @KafkaListener(topics = "role_create", groupId = "role_listener_group")
    public void onRoleCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为RoleManagement对象
            RoleManagement role = deserializeMessage(message);

            // 根据业务逻辑处理创建角色
            roleManagementService.createRole(role);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create role message: {}", message, e);
        }
    }

    @KafkaListener(topics = "role_update", groupId = "role_listener_group")
    public void onRoleUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为RoleManagement对象
            RoleManagement role = deserializeMessage(message);

            // 根据业务逻辑处理更新角色
            roleManagementService.updateRole(role);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update role message: {}", message, e);
        }
    }

    private RoleManagement deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到RoleManagement对象的反序列化
        return objectMapper.readValue(message, RoleManagement.class);
    }
}