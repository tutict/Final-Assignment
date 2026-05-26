package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.driver.DriverVehicle;
import com.tutict.finalassignmentbackend.service.driver.DriverVehicleService;
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
public class DriverVehicleKafkaListener {

    private static final Logger log = Logger.getLogger(DriverVehicleKafkaListener.class.getName());

    private final DriverVehicleService driverVehicleService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public DriverVehicleKafkaListener(DriverVehicleService driverVehicleService,
                                      IdempotentKafkaMessageProcessor messageProcessor) {
        this.driverVehicleService = driverVehicleService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.driver-vehicle.create:driver_vehicle_create}", groupId = "${kafka.groups.driver-vehicle:driverVehicleGroup}", concurrency = "3")
    public void onDriverVehicleCreateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message,
                                              Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processMessage(asKey(rawKey), message, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.driver-vehicle.update:driver_vehicle_update}", groupId = "${kafka.groups.driver-vehicle:driverVehicleGroup}", concurrency = "3")
    public void onDriverVehicleUpdateReceived(@Header(value = KafkaHeaders.RECEIVED_KEY, required = false) byte[] rawKey,
                                              @Payload String message,
                                              Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processMessage(asKey(rawKey), message, "update", ack);
    }

    private void processMessage(String idempotencyKey, String message, String action, Acknowledgment ack) {
        if (isBlank(idempotencyKey)) {
            log.warning("Received DriverVehicle event without idempotency key, skipping");
            acknowledge(ack);
            return;
        }
        messageProcessor.process(
                idempotencyKey,
                message,
                ack,
                "DriverVehicle",
                action,
                driverVehicleService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getId() != null) {
                        driverVehicleService.markHistorySuccess(key, result.getId());
                    }
                },
                (key, ex) -> driverVehicleService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private DriverVehicle processPayload(String message, String action) {
        DriverVehicle payload = messageProcessor.deserialize(message, DriverVehicle.class);
        if ("create".equalsIgnoreCase(action)) {
            payload.setId(null);
            return driverVehicleService.createBinding(payload);
        }
        if ("update".equalsIgnoreCase(action)) {
            return driverVehicleService.updateBinding(payload);
        }
        log.log(Level.WARNING, "Unsupported DriverVehicle action: {0}", action);
        return null;
    }

    private String asKey(byte[] rawKey) {
        return rawKey == null ? null : new String(rawKey);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void acknowledge(Acknowledgment acknowledgment) {
        if (acknowledgment != null) {
            acknowledgment.acknowledge();
        }
    }
}
