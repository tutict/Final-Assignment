package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


// 定义一个Kafka消息监听器类，用于处理权限管理相关的Kafka消息
@Component
public class PermissionManagementKafkaListener {

    // 初始化日志记录器
    private static final Logger log = LoggerFactory.getLogger(PermissionManagementKafkaListener.class);

    // 权限管理服务接口，用于处理权限的业务逻辑
    private final PermissionManagementService permissionManagementService;

    // 对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    // 构造函数，自动注入权限管理服务
    @Autowired
    public PermissionManagementKafkaListener(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }

    // 监听权限创建主题，处理权限创建消息
    @KafkaListener(topics = "permission_create", groupId = "permission_listener_group")
    public void onPermissionCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为PermissionManagement对象
                PermissionManagement permission = deserializeMessage(message);

                // 根据业务逻辑处理创建权限
                permissionManagementService.createPermission(permission);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create permission message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create permission message: {}", message, res.cause());
            }
        });
    }

    // 监听权限更新主题，处理权限更新消息
    @KafkaListener(topics = "permission_update", groupId = "permission_listener_group")
    public void onPermissionUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为PermissionManagement对象
                PermissionManagement permission = deserializeMessage(message);

                // 根据业务逻辑处理更新权限
                permissionManagementService.updatePermission(permission);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update permission message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update permission message: {}", message, res.cause());
            }
        });
    }

    // 反序列化JSON消息为PermissionManagement对象
    private PermissionManagement deserializeMessage(String message) throws JsonProcessingException {
        try {
            return objectMapper.readValue(message, PermissionManagement.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
