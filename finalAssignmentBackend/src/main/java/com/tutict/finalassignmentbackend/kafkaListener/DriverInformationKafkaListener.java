package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.mapper.DriverInformationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class DriverInformationKafkaListener {

    private static final Logger log = Logger.getLogger(DriverInformationKafkaListener.class.getName());

    private final DriverInformationMapper driverInformationMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public DriverInformationKafkaListener(DriverInformationMapper driverInformationMapper, ObjectMapper objectMapper) {
        this.driverInformationMapper = driverInformationMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "driver_information_create", groupId = "driverInformationGroup", concurrency = "3")
    public void onDriverInformationCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "driver_information_update", groupId = "driverInformationGroup", concurrency = "3")
    public void onDriverInformationUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            DriverInformation entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setDriverId(null);
                driverInformationMapper.insert(entity);
            } else if ("update".equals(action)) {
                driverInformationMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("DriverInformation %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s DriverInformation message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s DriverInformation message", action), e);
        }
    }

    private DriverInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DriverInformation.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
