package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


// 定义一个Kafka消息监听器，用于处理系统日志的创建和更新操作
@Component
public class SystemLogsKafkaListener {

    // 初始化日志记录器
    private static final Logger log = LoggerFactory.getLogger(SystemLogsKafkaListener.class);
    // 系统日志服务实例，用于执行日志的业务操作
    private final SystemLogsService systemLogsService;
    // 对象映射器，用于Kafka消息的反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    // 构造函数，通过依赖注入初始化SystemLogsService
    @Autowired
    public SystemLogsKafkaListener(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }

    // 监听"system_create"主题，处理系统日志创建消息
    @KafkaListener(topics = "system_create", groupId = "system_logs_listener_group", concurrency = "3")
    public void onSystemLogCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为SystemLogs对象
                SystemLogs systemLog = deserializeMessage(message);

                // 根据业务逻辑处理创建系统日志
                systemLogsService.createSystemLog(systemLog);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create system log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create system log message: {}", message, res.cause());
            }
        });
    }

    // 监听"system_update"主题，处理系统日志更新消息
    @KafkaListener(topics = "system_update", groupId = "system_logs_listener_group", concurrency = "3")
    public void onSystemLogUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为SystemLogs对象
                SystemLogs systemLog = deserializeMessage(message);

                // 根据业务逻辑处理更新系统日志
                systemLogsService.updateSystemLog(systemLog);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update system log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update system log message: {}", message, res.cause());
            }
        });
    }

    // 将JSON字符串反序列化为SystemLogs对象
    private SystemLogs deserializeMessage(String message) {
        try {
            // 实现JSON字符串到SystemLogs对象的反序列化
            return objectMapper.readValue(message, SystemLogs.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
