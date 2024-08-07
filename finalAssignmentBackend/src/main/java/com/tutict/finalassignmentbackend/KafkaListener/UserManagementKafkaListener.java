package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class UserManagementKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(UserManagementKafkaListener.class);
    private final UserManagementService userManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public UserManagementKafkaListener(UserManagementService userManagementService) {
        this.userManagementService = userManagementService;
    }

    @KafkaListener(topics = "user_create", groupId = "user_listener_group")
    public void onUserCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为UserManagement对象
                UserManagement user = deserializeMessage(message);

                // 根据业务逻辑处理创建用户
                userManagementService.createUser(user);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create user message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create user message: {}", message, res.cause());
            }
        });
    }

    @KafkaListener(topics = "user_update", groupId = "user_listener_group")
    public void onUserUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为UserManagement对象
                UserManagement user = deserializeMessage(message);

                // 根据业务逻辑处理更新用户
                userManagementService.updateUser(user);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update user message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update user message: {}", message, res.cause());
            }
        });
    }

    private UserManagement deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到UserManagement对象的反序列化
        return objectMapper.readValue(message, UserManagement.class);
    }
}