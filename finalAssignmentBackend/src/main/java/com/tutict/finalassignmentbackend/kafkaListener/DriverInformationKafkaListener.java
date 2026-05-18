package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
// Kafka 监听器，处理消息
public class DriverInformationKafkaListener {

    private static final Logger log = Logger.getLogger(DriverInformationKafkaListener.class.getName());

    private final DriverInformationService driverInformationService;
    private final ObjectMapper objectMapper;

    // 构造器注入依赖
    @Autowired
    public DriverInformationKafkaListener(DriverInformationService driverInformationService,
                                          ObjectMapper objectMapper) {
        this.driverInformationService = driverInformationService;
        this.objectMapper = objectMapper;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.driver-information.create:driver_information_create}", groupId = "${kafka.groups.driver-information:driverInformationGroup}", concurrency = "3")
    public void onDriverInformationCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                          @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for DriverInformation create (payload omitted)");
        processMessage(asKey(rawKey), message, "create");
        ack.acknowledge();
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.driver-information.update:driver_information_update}", groupId = "${kafka.groups.driver-information:driverInformationGroup}", concurrency = "3")
    public void onDriverInformationUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                          @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for DriverInformation update (payload omitted)");
        processMessage(asKey(rawKey), message, "update");
        ack.acknowledge();
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received driver information event without idempotency key, skipping");
            return;
        }
        DriverInformation payload = deserializeMessage(message);
        if (payload == null) {
            log.warning("Received driver information event with empty payload, skipping");
            return;
        }
        try {
            if (driverInformationService.shouldSkipProcessing(idempotencyKey)) {
                log.log(Level.INFO, "Skipping duplicate driver event (key={0}, action={1})",
                        new Object[]{idempotencyKey, action});
                return;
            }
            DriverInformation result;
            if ("create".equalsIgnoreCase(action)) {
                payload.setDriverId(null);
                result = driverInformationService.createDriver(payload);
            } else if ("update".equalsIgnoreCase(action)) {
                result = driverInformationService.updateDriver(payload);
            } else {
                log.log(Level.WARNING, "Unsupported driver action: {0}", action);
                return;
            }
            driverInformationService.markHistorySuccess(idempotencyKey,
                    result.getDriverId() != null ? result.getDriverId() : null);
        } catch (Exception ex) {
            driverInformationService.markHistoryFailure(idempotencyKey, ex.getMessage());
            log.log(Level.SEVERE,
                    String.format("Error processing driver event (key=%s, action=%s)", idempotencyKey, action),
                    ex);
            throw ex;
        }
    }
    private DriverInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DriverInformation.class);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to deserialize Kafka message (payload omitted)", ex);
            throw new IllegalArgumentException("Failed to deserialize Kafka message", ex);
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
