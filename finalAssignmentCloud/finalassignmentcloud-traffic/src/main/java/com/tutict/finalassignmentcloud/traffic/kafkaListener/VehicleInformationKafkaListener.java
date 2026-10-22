package com.tutict.finalassignmentcloud.traffic.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.entity.VehicleInformation;
import com.tutict.finalassignmentcloud.reliability.IdempotencyConflictException;
import com.tutict.finalassignmentcloud.reliability.IdempotencyReplayException;
import com.tutict.finalassignmentcloud.traffic.service.VehicleInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;
import com.tutict.finalassignmentcloud.reliability.LedgerFingerprint;

@Service
@EnableKafka
// Kafka 监听器，处理消息
public class VehicleInformationKafkaListener {

    private static final Logger log = Logger.getLogger(VehicleInformationKafkaListener.class.getName());

    private final VehicleInformationService vehicleInformationService;
    private final ObjectMapper objectMapper;

    @Autowired
    // 构造器注入依赖
    public VehicleInformationKafkaListener(VehicleInformationService vehicleInformationService, ObjectMapper objectMapper) {
        this.vehicleInformationService = vehicleInformationService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息（创建）
    @KafkaListener(topics = "vehicle_information_create", groupId = "vehicleInformationGroup", concurrency = "3")
    public void onVehicleInformationCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                    @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for create");
        processMessage(asKey(rawKey), message, "create");
    }

    // 监听 Kafka 消息（更新）
    @KafkaListener(topics = "vehicle_information_update", groupId = "vehicleInformationGroup", concurrency = "3")
    public void onVehicleInformationUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                                    @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for update");
        processMessage(asKey(rawKey), message, "update");
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        String key = idempotencyKey;
        if (isBlank(key)) {
            // 没有 key 时用消息内容派生稳定键，避免重投产生重复数据。
            key = LedgerFingerprint.sha256(action + "|" + message);
            log.log(Level.WARNING, "VehicleInformation event without key, using derived key {0}", key);
        }
        if (vehicleInformationService.shouldSkipProcessing(key)) {
            log.log(Level.INFO, "Skipping duplicate VehicleInformation event (key={0}, action={1})",
                    new Object[]{key, action});
            return;
        }
        VehicleInformation entity = deserializeMessage(message);
        try {
            vehicleInformationService.checkAndInsertIdempotency(key, entity, action);
        } catch (IdempotencyReplayException | IdempotencyConflictException ex) {
            log.log(Level.INFO, "Skipping already applied VehicleInformation event (key={0})", key);
            return;
        }
        try {
            if ("create".equals(action)) {
                entity.setVehicleId(null);
                vehicleInformationService.createVehicleInformation(entity);
            } else if ("update".equals(action)) {
                vehicleInformationService.updateVehicleInformation(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            vehicleInformationService.markHistorySuccess(key, entity.getVehicleId());
            log.info(String.format("VehicleInformation %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            vehicleInformationService.markHistoryFailure(key, e.getMessage());
            log.log(Level.SEVERE, String.format("Error processing %s VehicleInformation message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s VehicleInformation message", action), e);
        }
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    // 反序列化消息体
    private VehicleInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, VehicleInformation.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
