package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.driver.DriverInformation;
import com.tutict.finalassignmentbackend.service.driver.DriverInformationService;
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
    private final IdempotentKafkaMessageProcessor messageProcessor;

    // 构造器注入依赖
    @Autowired
    public DriverInformationKafkaListener(DriverInformationService driverInformationService,
                                          IdempotentKafkaMessageProcessor messageProcessor) {
        this.driverInformationService = driverInformationService;
        this.messageProcessor = messageProcessor;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.driver-information.create:driver_information_create}", groupId = "${kafka.groups.driver-information:driverInformationGroup}", concurrency = "3")
    public void onDriverInformationCreate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                          @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for DriverInformation create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.driver-information.update:driver_information_update}", groupId = "${kafka.groups.driver-information:driverInformationGroup}", concurrency = "3")
    public void onDriverInformationUpdate(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                          @Payload String message,
                                      Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for DriverInformation update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    // 统一处理消息并执行业务逻辑
    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received driver information event without idempotency key, skipping");
            ack.acknowledge();
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "DriverInformation",
                action,
                driverInformationService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getDriverId() != null) {
                        driverInformationService.markHistorySuccess(key, result.getDriverId());
                    }
                },
                (key, ex) -> driverInformationService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private DriverInformation processPayload(String message, String action) {
        DriverInformation payload = messageProcessor.deserialize(message, DriverInformation.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setDriverId(null);
            return driverInformationService.createDriver(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return driverInformationService.updateDriver(payload);
        }
        log.log(Level.WARNING, "Unsupported driver action: {0}", action);
        return null;
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    // 判空
    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
