package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class DriverInformationKafkaListener {

    // 日志记录器
    private static final Logger log = LoggerFactory.getLogger(DriverInformationKafkaListener.class);
    // 驾驶员信息服务类
    private final DriverInformationService driverInformationService;
    // 对象映射器，用于JSON处理
    private final ObjectMapper objectMapper = new ObjectMapper();

    // 构造函数，自动装配DriverInformationService
    @Autowired
    public DriverInformationKafkaListener(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    // 监听驾驶员创建消息
    @KafkaListener(topics = "driver_create", groupId = "driver_listener_group")
    public void onDriverCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为DriverInformation对象
                DriverInformation driverInformation = deserializeMessage(message);

                // 创建驾驶员信息
                driverInformationService.createDriver(driverInformation);
                promise.complete();

            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create driver message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 确认消息已被成功处理
                acknowledgment.acknowledge();
            } else {
                // 处理失败，记录错误信息
                log.error("Error processing create driver message: {}", message, res.cause());
            }
        });
    }

    // 监听驾驶员更新消息
    @KafkaListener(topics = "driver_update", groupId = "driver_listener_group")
    public void onDriverUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为DriverInformation对象
                DriverInformation driverInformation = deserializeMessage(message);

                // 更新驾驶员信息
                driverInformationService.updateDriver(driverInformation);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update driver message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 确认消息已被成功处理
                acknowledgment.acknowledge();
            } else {
                // 处理失败，记录错误信息
                log.error("Error processing update driver message: {}", message, res.cause());
            }
        });
    }

    // 反序列化消息内容为DriverInformation对象
    private DriverInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到DriverInformation对象的反序列化
        return objectMapper.readValue(message, DriverInformation.class);
    }
}
