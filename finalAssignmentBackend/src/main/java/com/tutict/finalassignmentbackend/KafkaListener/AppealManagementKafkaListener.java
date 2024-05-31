package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import io.vertx.core.Future;
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

    @KafkaListener(topics = "appeal_create", groupId = "create_group")
    public void onAppealCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                AppealManagement appealManagement = deserializeMessage(message);
                appealManagementService.createAppeal(appealManagement);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing create appeal message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create appeal message: {}", message, res.cause());
            }
        });
    }

    @KafkaListener(topics = "appeal_updated", groupId = "create_group")
    public void onAppealUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                AppealManagement appealManagement = deserializeMessage(message);
                appealManagementService.updateAppeal(appealManagement);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing update appeal message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update appeal message: {}", message, res.cause());
            }
        });
    }

    private AppealManagement deserializeMessage(String message) throws JsonProcessingException {
        return objectMapper.readValue(message, AppealManagement.class);
    }
}
