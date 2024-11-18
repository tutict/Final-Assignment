package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.OperationLog;
import com.tutict.finalassignmentbackend.service.OperationLogService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class OperationLogKafkaListener {

    // 日志记录器，用于记录操作日志Kafka监听器的操作
    private static final Logger log = LoggerFactory.getLogger(OperationLogKafkaListener.class);

    // 操作日志服务接口，用于处理操作日志的业务逻辑
    private final OperationLogService operationLogService;

    // 对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    // 构造函数，通过@Autowired自动装配OperationLogService实例
    @Autowired
    public OperationLogKafkaListener(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }

    // 监听Kafka主题"operation_create"，处理操作日志创建事件
    @KafkaListener(topics = "operation_create", groupId = "operation_listener_group", concurrency = "3")
    public void onOperationLogCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OperationLog对象
                OperationLog operationLog = deserializeMessage(message);

                // 根据业务逻辑处理创建操作日志
                operationLogService.createOperationLog(operationLog);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create operation log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create operation log message: {}", message, res.cause());
            }
        });
    }

    // 监听Kafka主题"operation_update"，处理操作日志更新事件
    @KafkaListener(topics = "operation_update", groupId = "operation_listener_group", concurrency = "3")
    public void onOperationLogUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OperationLog对象
                OperationLog operationLog = deserializeMessage(message);

                // 根据业务逻辑处理更新操作日志
                operationLogService.updateOperationLog(operationLog);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update operation log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update operation log message: {}", message, res.cause());
            }
        });
    }

    // 将JSON字符串反序列化为OperationLog对象
    private OperationLog deserializeMessage(String message) {
        try {
            // 实现JSON字符串到OperationLog对象的反序列化
            return objectMapper.readValue(message, OperationLog.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
