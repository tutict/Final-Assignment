package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DriverVehicle;
import com.tutict.finalassignmentbackend.service.DriverVehicleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
// Kafka 监听器，处理消息
public class DriverVehicleKafkaListener {

    private static final Logger log = Logger.getLogger(DriverVehicleKafkaListener.class.getName());

    private final DriverVehicleService driverVehicleService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public DriverVehicleKafkaListener(DriverVehicleService driverVehicleService,
                                      ObjectMapper objectMapper) {
        this.driverVehicleService = driverVehicleService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "driver_vehicle_create", groupId = "driverVehicleGroup", concurrency = "3")
    public void onDriverVehicleCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "create"));
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "driver_vehicle_update", groupId = "driverVehicleGroup", concurrency = "3")
    public void onDriverVehicleUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        Thread.ofVirtual().start(() -> processMessage(asKey(rawKey), message, "update"));
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received DriverVehicle event without idempotency key, skipping");
            return;
        }
        try {
            DriverVehicle payload = deserializeMessage(message);
            if (payload == null) {
                log.warning("Received DriverVehicle event with empty payload, skipping");
                return;
            }
            if (driverVehicleService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate DriverVehicle event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            DriverVehicle result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setId(null);
                result = driverVehicleService.createBinding(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = driverVehicleService.updateBinding(payload);
            } else {
                log.log(Level.WARNING, "Unsupported DriverVehicle action: {0}", action);
                return;
            }
            driverVehicleService.markHistorySuccess(idempotencyKey, result.getId());
            log.info(String.format("DriverVehicle %s action processed successfully (key=%s)", action, idempotencyKey));
        } catch (Exception ex) {
            driverVehicleService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing %s DriverVehicle message (key=%s, payload omitted)", action, idempotencyKey),
                    ex);
            throw ex;
        }
    }
    private DriverVehicle deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DriverVehicle.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize DriverVehicle message (payload omitted)");
            return null;
        }
    }
    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    // 判空
    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
