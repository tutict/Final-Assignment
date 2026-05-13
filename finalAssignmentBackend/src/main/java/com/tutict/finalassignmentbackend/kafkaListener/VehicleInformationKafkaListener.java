package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
// Kafka 监听器，处理消息
public class VehicleInformationKafkaListener {

    private static final Logger log = Logger.getLogger(VehicleInformationKafkaListener.class.getName());

    private final VehicleInformationMapper vehicleInformationMapper;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public VehicleInformationKafkaListener(VehicleInformationMapper vehicleInformationMapper, ObjectMapper objectMapper) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "vehicle_information_create", groupId = "vehicleInformationGroup", concurrency = "3")
    public void onVehicleInformationCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "vehicle_information_update", groupId = "vehicleInformationGroup", concurrency = "3")
    public void onVehicleInformationUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String message, String action) {
        try {
            VehicleInformation entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setVehicleId(null);
                vehicleInformationMapper.insert(entity);
            } else if ("update".equals(action)) {
                vehicleInformationMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("VehicleInformation %s action processed successfully", action));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s VehicleInformation message (payload omitted)", action), e);
            throw new RuntimeException(String.format("Failed to process %s VehicleInformation message", action), e);
        }
    }
    private VehicleInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, VehicleInformation.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message (payload omitted)");
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
