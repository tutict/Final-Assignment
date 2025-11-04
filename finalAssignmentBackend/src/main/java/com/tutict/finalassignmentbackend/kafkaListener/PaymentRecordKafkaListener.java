package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.PaymentRecord;
import com.tutict.finalassignmentbackend.mapper.PaymentRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class PaymentRecordKafkaListener {

    private static final Logger log = Logger.getLogger(PaymentRecordKafkaListener.class.getName());

    private final PaymentRecordMapper paymentRecordMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public PaymentRecordKafkaListener(PaymentRecordMapper paymentRecordMapper, ObjectMapper objectMapper) {
        this.paymentRecordMapper = paymentRecordMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "payment_record_create", groupId = "paymentRecordGroup", concurrency = "3")
    public void onPaymentRecordCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "payment_record_update", groupId = "paymentRecordGroup", concurrency = "3")
    public void onPaymentRecordUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            PaymentRecord entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setPaymentId(null);
                paymentRecordMapper.insert(entity);
            } else if ("update".equals(action)) {
                paymentRecordMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("PaymentRecord %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s PaymentRecord message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s PaymentRecord message", action), e);
        }
    }

    private PaymentRecord deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, PaymentRecord.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
