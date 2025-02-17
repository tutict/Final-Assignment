package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.logging.Level;
import java.util.logging.Logger;


// 定义一个Kafka消息监听器类，用于处理扣款信息的创建和更新
@Service
@EnableKafka
public class DeductionInformationKafkaListener {

    private static final Logger log = Logger.getLogger(DeductionInformationKafkaListener.class.getName());

    private final DeductionInformationService deductionInformationService;
    private final ObjectMapper objectMapper;

    @Autowired
    public DeductionInformationKafkaListener(DeductionInformationService deductionInformationService, ObjectMapper objectMapper) {
        this.deductionInformationService = deductionInformationService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "deduction_create", groupId = "deductionGroup")
    @Transactional
    public void onDeductionCreateReceived(String message) {
        processMessage(message, "create", deductionInformationService::createDeduction);
    }

    @KafkaListener(topics = "deduction_update", groupId = "deductionGroup")
    @Transactional
    public void onDeductionUpdateReceived(String message) {
        processMessage(message, "update", deductionInformationService::updateDeduction);
    }

    private void processMessage(String message, String action, MessageProcessor<DeductionInformation> processor) {
        try {
            DeductionInformation deductionInformation = deserializeMessage(message);
            if ("create".equals(action)) {
                deductionInformation.setDeductionId(null);
                processor.process(deductionInformation);
            }
            log.info(String.format("Deduction %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s deduction message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s deduction message", action), e);
        }
    }

    private DeductionInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DeductionInformation.class);
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