package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class SystemLogsKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(SystemLogsKafkaListener.class);
    private final SystemLogsService systemLogsService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public SystemLogsKafkaListener(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }

    @KafkaListener(topics = "system_create", groupId = "system_logs_listener_group")
    public void onSystemLogCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为SystemLogs对象
            SystemLogs systemLog = deserializeMessage(message);

            // 根据业务逻辑处理创建系统日志
            systemLogsService.createSystemLog(systemLog);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create system log message: {}", message, e);
        }
    }

    @KafkaListener(topics = "system_update", groupId = "system_logs_listener_group")
    public void onSystemLogUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为SystemLogs对象
            SystemLogs systemLog = deserializeMessage(message);

            // 根据业务逻辑处理更新系统日志
            systemLogsService.updateSystemLog(systemLog);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update system log message: {}", message, e);
        }
    }

    private SystemLogs deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到SystemLogs对象的反序列化
        return objectMapper.readValue(message, SystemLogs.class);
    }
}