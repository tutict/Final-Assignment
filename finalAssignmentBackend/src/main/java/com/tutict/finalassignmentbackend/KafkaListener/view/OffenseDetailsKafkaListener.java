package com.tutict.finalassignmentbackend.KafkaListener.view;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import com.tutict.finalassignmentbackend.service.view.OffenseDetailsService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

@Component
public class OffenseDetailsKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(OffenseDetailsKafkaListener.class);
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();
    private final OffenseDetailsService offenseDetailsService;

    @Autowired
    public OffenseDetailsKafkaListener(OffenseDetailsService offenseDetailsService) {
        this.offenseDetailsService = offenseDetailsService;
    }

    @KafkaListener(topics = "offense_details_topic", groupId = "offense_details_group")
    public void onOffenseDetailsReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OffenseDetails对象
                OffenseDetails offenseDetails = deserializeMessage(message);

                // 处理收到的OffenseDetails对象，例如保存到数据库
                offenseDetailsService.saveOffenseDetails(offenseDetails);

                // 确认消息处理成功
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing appeal message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 消息处理成功，确认消息处理成功
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing appeal message: {}", message, res.cause());
            }
        });
    }

    private OffenseDetails deserializeMessage(String message) throws JsonProcessingException {
        try {
            return objectMapper.readValue(message, OffenseDetails.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
