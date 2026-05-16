package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
// Kafka 监听器，处理消息
public class VehicleInformationKafkaListener {

    private static final Logger log = Logger.getLogger(VehicleInformationKafkaListener.class.getName());

    private final VehicleInformationService vehicleInformationService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public VehicleInformationKafkaListener(VehicleInformationService vehicleInformationService, ObjectMapper objectMapper) {
        this.vehicleInformationService = vehicleInformationService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "vehicle_information_create", groupId = "vehicleInformationGroup", concurrency = "3")
    public void onVehicleInformationCreateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processRecord(record, "create", ack);
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "vehicle_information_update", groupId = "vehicleInformationGroup", concurrency = "3")
    public void onVehicleInformationUpdateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processRecord(record, "update", ack);
    }

    private void processRecord(ConsumerRecord<String, String> record, String action, Acknowledgment ack) {
        String idempotencyKey = record.key();
        if (idempotencyKey != null && vehicleInformationService.shouldSkipProcessing(idempotencyKey)) {
            log.log(Level.INFO, "Skipping duplicate VehicleInformation message: key={0}", idempotencyKey);
            ack.acknowledge();
            return;
        }
        try {
            VehicleInformation entity = processMessage(record.value(), action);
            if (idempotencyKey != null) {
                vehicleInformationService.markHistorySuccess(idempotencyKey, entity.getVehicleId());
            }
            ack.acknowledge();
        } catch (Exception e) {
            if (idempotencyKey != null) {
                vehicleInformationService.markHistoryFailure(idempotencyKey, e.getMessage());
            }
            log.log(Level.SEVERE, "VehicleInformation message processing failed", e);
            throw e;
        }
    }

    // 统一处理消息并执行业务逻辑
    private VehicleInformation processMessage(String message, String action) {
        try {
            VehicleInformation entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setVehicleId(null);
                entity = vehicleInformationService.createVehicleInformation(entity);
            } else if ("update".equals(action)) {
                entity = vehicleInformationService.updateVehicleInformation(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return entity;
            }
            log.info(String.format("VehicleInformation %s action processed successfully", action));
            return entity;
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
