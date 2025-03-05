package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;


@Service
@EnableKafka
public class OffenseInformationKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseInformationKafkaListener.class.getName());

    private final OffenseInformationService offenseInformationService;
    private final ObjectMapper objectMapper;

    @Autowired
    public OffenseInformationKafkaListener(OffenseInformationService offenseInformationService, ObjectMapper objectMapper) {
        this.offenseInformationService = offenseInformationService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "offense_create", groupId = "offenseGroup")
    public void onOffenseCreateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "create", offenseInformationService::createOffense));
    }

    @KafkaListener(topics = "offense_update", groupId = "offenseGroup")
    public void onOffenseUpdateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "update", offenseInformationService::updateOffense));
    }

    private void processMessage(String message, String action, MessageProcessor<OffenseInformation> processor) {
        try {
            OffenseInformation offenseInformation = deserializeMessage(message);
            if ("create".equals(action)) {
                offenseInformation.setOffenseId(null);
            }
            processor.process(offenseInformation);
            log.info(String.format("Offense %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s offense message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s offense message", action), e);
        }
    }

    private OffenseInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseInformation.class);
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