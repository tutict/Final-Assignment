package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.driver.VehicleInformation;
import com.tutict.finalassignmentbackend.service.driver.VehicleInformationService;
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
    private final IdempotentKafkaMessageProcessor messageProcessor;

    // 构造器注入依赖
    @Autowired
    public VehicleInformationKafkaListener(VehicleInformationService vehicleInformationService,
                                           IdempotentKafkaMessageProcessor messageProcessor) {
        this.vehicleInformationService = vehicleInformationService;
        this.messageProcessor = messageProcessor;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.vehicle.create:vehicle_information_create}", groupId = "${kafka.groups.vehicle:vehicleInformationGroup}", concurrency = "3")
    public void onVehicleInformationCreateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processRecord(record, "create", ack);
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.vehicle.update:vehicle_information_update}", groupId = "${kafka.groups.vehicle:vehicleInformationGroup}", concurrency = "3")
    public void onVehicleInformationUpdateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processRecord(record, "update", ack);
    }

    private void processRecord(ConsumerRecord<String, String> record, String action, Acknowledgment ack) {
        messageProcessor.process(
                record,
                ack,
                "VehicleInformation",
                action,
                vehicleInformationService::shouldSkipProcessing,
                payload -> processMessage(payload, action),
                (key, entity) -> {
                    if (entity != null && entity.getVehicleId() != null) {
                        vehicleInformationService.markHistorySuccess(key, entity.getVehicleId());
                    }
                },
                (key, ex) -> vehicleInformationService.markHistoryFailure(key, ex.getMessage())
        );
    }

    // 统一处理消息并执行业务逻辑
    private VehicleInformation processMessage(String message, String action) {
        try {
            VehicleInformation entity = messageProcessor.deserialize(message, VehicleInformation.class);
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
}
