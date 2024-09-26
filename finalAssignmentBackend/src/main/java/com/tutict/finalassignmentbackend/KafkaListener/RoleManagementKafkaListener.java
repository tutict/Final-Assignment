package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.service.RoleManagementService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class RoleManagementKafkaListener {
    // 日志记录器，用于记录应用的日志信息
    private static final Logger log = LoggerFactory.getLogger(RoleManagementKafkaListener.class);
    // 角色管理服务，用于处理角色的创建和更新
    private final RoleManagementService roleManagementService;
    // 对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Autowired
    public RoleManagementKafkaListener(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }

    @KafkaListener(topics = "role_create", groupId = "role_listener_group")
    public void onRoleCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为RoleManagement对象
                RoleManagement role = deserializeMessage(message);

                // 根据业务逻辑处理创建角色
                roleManagementService.createRole(role);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create role message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create role message: {}", message, res.cause());
            }
        });
    }

    @KafkaListener(topics = "role_update", groupId = "role_listener_group")
    public void onRoleUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为RoleManagement对象
                RoleManagement role = deserializeMessage(message);

                // 根据业务逻辑处理更新角色
                roleManagementService.updateRole(role);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update role message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update role message: {}", message, res.cause());
            }
        });
    }

    private RoleManagement deserializeMessage(String message) throws JsonProcessingException {
        try {
            // 实现JSON字符串到RoleManagement对象的反序列化
            return objectMapper.readValue(message, RoleManagement.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
