package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.logging.Level;
import java.util.logging.Logger;


@Service
@EnableKafka
public class DriverInformationKafkaListener {

    private static final Logger log = Logger.getLogger(DriverInformationKafkaListener.class.getName());

    private final DriverInformationService driverInformationService;
    private final ObjectMapper objectMapper;

    @Autowired
    public DriverInformationKafkaListener(DriverInformationService driverInformationService, ObjectMapper objectMapper) {
        this.driverInformationService = driverInformationService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "driver_create", groupId = "driverGroup")
    @Transactional
    public void onDriverCreateReceived(String message) {
        processMessage(message, "create", driverInformationService::createDriver);
    }

    @KafkaListener(topics = "driver_update", groupId = "driverGroup")
    @Transactional
    public void onDriverUpdateReceived(String message) {
        processMessage(message, "update", driverInformationService::updateDriver);
    }

    private void processMessage(String message, String action, MessageProcessor<DriverInformation> processor) {
        try {
            DriverInformation driverInformation = deserializeMessage(message);
            if ("create".equals(action)) {
                driverInformation.setDriverId(null);
                processor.process(driverInformation);
            }
            log.info(String.format("Driver %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s driver message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s driver message", action), e);
        }
    }

    private DriverInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DriverInformation.class);
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