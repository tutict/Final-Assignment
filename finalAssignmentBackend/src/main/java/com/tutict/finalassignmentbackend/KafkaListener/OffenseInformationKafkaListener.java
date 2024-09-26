package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class OffenseInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(OffenseInformationKafkaListener.class);
    private final OffenseInformationService offenseInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Autowired
    public OffenseInformationKafkaListener(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    @KafkaListener(topics = "offense_create", groupId = "offense_listener_group")
    public void onOffenseCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OffenseInformation对象
                OffenseInformation offenseInformation = deserializeMessage(message);

                // 根据业务逻辑处理创建违法行为信息
                offenseInformationService.createOffense(offenseInformation);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create offense message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create offense message: {}", message, res.cause());
            }
        });
    }

    @KafkaListener(topics = "offense_update", groupId = "offense_listener_group")
    public void onOffenseUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OffenseInformation对象
                OffenseInformation offenseInformation = deserializeMessage(message);

                // 根据业务逻辑处理更新违法行为信息
                offenseInformationService.updateOffense(offenseInformation);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update offense message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update offense message: {}", message, res.cause());
            }
        });
    }

    private OffenseInformation deserializeMessage(String message) throws JsonProcessingException {
        try {
            // 实现JSON字符串到OffenseInformation对象的反序列化
            return objectMapper.readValue(message, OffenseInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
