package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DriverVehicle;
import com.tutict.finalassignmentbackend.mapper.DriverVehicleMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class DriverVehicleKafkaListener {

    private static final Logger log = Logger.getLogger(DriverVehicleKafkaListener.class.getName());

    private final DriverVehicleMapper driverVehicleMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public DriverVehicleKafkaListener(DriverVehicleMapper driverVehicleMapper, ObjectMapper objectMapper) {
        this.driverVehicleMapper = driverVehicleMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "driver_vehicle_create", groupId = "driverVehicleGroup", concurrency = "3")
    public void onDriverVehicleCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "driver_vehicle_update", groupId = "driverVehicleGroup", concurrency = "3")
    public void onDriverVehicleUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            DriverVehicle entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setId(null);
                driverVehicleMapper.insert(entity);
            } else if ("update".equals(action)) {
                driverVehicleMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("DriverVehicle %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s DriverVehicle message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s DriverVehicle message", action), e);
        }
    }

    private DriverVehicle deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DriverVehicle.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
