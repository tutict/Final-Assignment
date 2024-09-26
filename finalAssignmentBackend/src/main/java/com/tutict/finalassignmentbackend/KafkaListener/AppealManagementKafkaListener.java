package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


// 声明一个Kafka监听器组件，用于处理申诉管理相关的消息
@Component
public class AppealManagementKafkaListener {

    // 初始化日志记录器
    private static final Logger log = LoggerFactory.getLogger(AppealManagementKafkaListener.class);
    // 依赖的申诉管理服务
    private final AppealManagementService appealManagementService;
    // 对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    // 构造函数，自动注入申诉管理服务
    @Autowired
    public AppealManagementKafkaListener(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    // 监听Kafka主题中的申诉创建消息
    @KafkaListener(topics = "appeal_create", groupId = "create_group")
    public void onAppealCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息并创建申诉
                AppealManagement appealManagement = deserializeMessage(message);
                appealManagementService.createAppeal(appealManagement);
                promise.complete();
            } catch (Exception e) {
                // 记录错误并失败承诺
                log.error("Error processing create appeal message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 处理成功，确认消息
                acknowledgment.acknowledge();
            } else {
                // 记录处理失败的错误
                log.error("Error processing create appeal message: {}", message, res.cause());
            }
        });
    }

    // 监听Kafka主题中的申诉更新消息
    @KafkaListener(topics = "appeal_updated", groupId = "create_group")
    public void onAppealUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息并更新申诉
                AppealManagement appealManagement = deserializeMessage(message);
                appealManagementService.updateAppeal(appealManagement);
                promise.complete();
            } catch (Exception e) {
                // 记录错误并失败承诺
                log.error("Error processing update appeal message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 处理成功，确认消息
                acknowledgment.acknowledge();
            } else {
                // 记录处理失败的错误
                log.error("Error processing update appeal message: {}", message, res.cause());
            }
        });
    }

    // 将JSON字符串反序列化为AppealManagement对象
    private AppealManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, AppealManagement.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

}
