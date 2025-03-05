package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

// 定义一个Kafka消息监听器，用于处理系统日志的创建和更新操作
@Service
@EnableKafka
public class SystemLogsKafkaListener {

    private static final Logger log = Logger.getLogger(SystemLogsKafkaListener.class.getName());

    private final SystemLogsService systemLogsService;
    private final ObjectMapper objectMapper;

    @Autowired
    public SystemLogsKafkaListener(SystemLogsService systemLogsService, ObjectMapper objectMapper) {
        this.systemLogsService = systemLogsService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "system_create", groupId = "systemLogGroup", concurrency = "3")
    public void onSystemLogCreateReceived(String message) {
        // 使用虚拟线程处理消息
        Thread.ofVirtual().start(() -> processMessage(message, "create", systemLogsService::createSystemLog));
    }

    @KafkaListener(topics = "system_update", groupId = "systemLogGroup", concurrency = "3")
    public void onSystemLogUpdateReceived(String message) {
        // 使用虚拟线程处理消息
        Thread.ofVirtual().start(() -> processMessage(message, "update", systemLogsService::updateSystemLog));
    }

    private void processMessage(String message, String action, MessageProcessor<SystemLogs> processor) {
        try {
            SystemLogs systemLog = deserializeMessage(message);
            if ("create".equals(action)) {
                systemLog.setLogId(null); // 让数据库自增
            }
            processor.process(systemLog);
            log.info(String.format("System log %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s system log message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s system log message", action), e);
        }
    }

    private SystemLogs deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SystemLogs.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: " + message, e);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }

    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}