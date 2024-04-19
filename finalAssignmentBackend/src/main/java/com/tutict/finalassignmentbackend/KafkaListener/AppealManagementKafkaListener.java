package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

@Component
public class AppealManagementKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(AppealManagementKafkaListener.class);
    private final AppealManagementService appealManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public AppealManagementKafkaListener(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    // 监听"appeal-create"主题的消息
    @KafkaListener(topics = "appeal_create", groupId = "group_id")
    public void onAppealCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为AppealManagement对象
            AppealManagement appealManagement = deserializeMessage(message);

            // 调用服务层方法处理创建申述逻辑
            appealManagementService.createAppeal(appealManagement);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create appeal message: {}", message, e);
        }
    }

    // 监听"appeal-updated"主题的消息
    @KafkaListener(topics = "appeal_updated", groupId = "group_id")
    public void onAppealUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为AppealManagement对象
            AppealManagement appealManagement = deserializeMessage(message);

            // 调用服务层方法处理更新申述逻辑
            appealManagementService.updateAppeal(appealManagement);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update appeal message: {}", message, e);
        }
    }

    private AppealManagement deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到AppealManagement对象的反序列化
        return objectMapper.readValue(message, AppealManagement.class);
    }
}