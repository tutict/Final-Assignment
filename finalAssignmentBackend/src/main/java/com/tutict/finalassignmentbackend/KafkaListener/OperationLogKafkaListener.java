package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.service.OperationLogService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class OperationLogKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(OperationLogKafkaListener.class);
    private final OperationLogService operationLogService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public OperationLogKafkaListener(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }

    @KafkaListener(topics = "operation_create", groupId = "operation_listener_group")
    public void onOperationLogCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为OperationLog对象
            OperationLog operationLog = deserializeMessage(message);

            // 根据业务逻辑处理创建操作日志
            operationLogService.createOperationLog(operationLog);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create operation log message: {}", message, e);
        }
    }

    @KafkaListener(topics = "operation_update", groupId = "operation_listener_group")
    public void onOperationLogUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为OperationLog对象
            OperationLog operationLog = deserializeMessage(message);

            // 根据业务逻辑处理更新操作日志
            operationLogService.updateOperationLog(operationLog);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update operation log message: {}", message, e);
        }
    }

    private OperationLog deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到OperationLog对象的反序列化
        return objectMapper.readValue(message, OperationLog.class);
    }
}