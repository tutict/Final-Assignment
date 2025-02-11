package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.service.LoginLogService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class LoginLogKafkaListener {

    // 日志记录器
    private static final Logger log = LoggerFactory.getLogger(LoginLogKafkaListener.class);
    // 登录日志服务接口
    private final LoginLogService loginLogService;
    // 对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Autowired
    public LoginLogKafkaListener(LoginLogService loginLogService) {
        this.loginLogService = loginLogService;
    }

    @KafkaListener(topics = "login_create", groupId = "login_listener_group", concurrency = "3")
    public void onLoginLogCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为LoginLog对象
                LoginLog loginLog = deserializeMessage(message);

                // 根据业务逻辑处理创建登录日志
                loginLogService.createLoginLog(loginLog);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create login log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create login log message: {}", message, res.cause());
            }
        });
    }

    @KafkaListener(topics = "login_update", groupId = "login_listener_group", concurrency = "3")
    public void onLoginLogUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为LoginLog对象
                LoginLog loginLog = deserializeMessage(message);

                // 根据业务逻辑处理更新登录日志
                loginLogService.updateLoginLog(loginLog);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update login log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update login log message: {}", message, res.cause());
            }
        });
    }

    private LoginLog deserializeMessage(String message) {
        try {
            // 实现JSON字符串到LoginLog对象的反序列化
            return objectMapper.readValue(message, LoginLog.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
