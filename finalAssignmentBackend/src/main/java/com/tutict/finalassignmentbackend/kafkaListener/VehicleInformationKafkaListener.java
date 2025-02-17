package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.logging.Level;
import java.util.logging.Logger;

// 定义一个Kafka消息监听器，用于处理车辆信息的创建和更新操作
@Service
@EnableKafka
public class VehicleInformationKafkaListener {

    private static final Logger log = Logger.getLogger(VehicleInformationKafkaListener.class.getName());

    private final VehicleInformationService vehicleInformationService;
    private final ObjectMapper objectMapper;

    @Autowired
    public VehicleInformationKafkaListener(VehicleInformationService vehicleInformationService, ObjectMapper objectMapper) {
        this.vehicleInformationService = vehicleInformationService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "vehicle_create", groupId = "vehicleGroup")
    @Transactional
    public void onVehicleCreateReceived(String message) {
        processMessage(message, "create", vehicleInformationService::createVehicleInformation);
    }

    @KafkaListener(topics = "vehicle_update", groupId = "vehicleGroup")
    @Transactional
    public void onVehicleUpdateReceived(String message) {
        processMessage(message, "update", vehicleInformationService::updateVehicleInformation);
    }

    private void processMessage(String message, String action, MessageProcessor<VehicleInformation> processor) {
        try {
            VehicleInformation vehicleInformation = deserializeMessage(message);
            if ("create".equals(action)) {
                vehicleInformation.setVehicleId(null);
                processor.process(vehicleInformation);
            }
            log.info(String.format("Vehicle %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s vehicle information message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s vehicle information message", action), e);
        }
    }

    private VehicleInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, VehicleInformation.class);
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