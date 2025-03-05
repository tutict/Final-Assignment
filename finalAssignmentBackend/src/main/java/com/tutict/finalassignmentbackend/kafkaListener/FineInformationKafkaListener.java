package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;


// 定义一个Kafka消息监听器，用于处理罚款信息的相关消息
@Service
@EnableKafka
public class FineInformationKafkaListener {

    private static final Logger log = Logger.getLogger(FineInformationKafkaListener.class.getName());

    private final FineInformationService fineInformationService;
    private final ObjectMapper objectMapper;

    @Autowired
    public FineInformationKafkaListener(FineInformationService fineInformationService, ObjectMapper objectMapper) {
        this.fineInformationService = fineInformationService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "fine_create", groupId = "fineGroup")
    public void onFineCreateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "create", fineInformationService::createFine));
    }

    @KafkaListener(topics = "fine_update", groupId = "fineGroup")
    public void onFineUpdateReceived(String message) {
        Thread.ofVirtual().start(() -> processMessage(message, "update", fineInformationService::updateFine));
    }

    private void processMessage(String message, String action, MessageProcessor<FineInformation> processor) {
        try {
            FineInformation fineInformation = deserializeMessage(message);
            if ("create".equals(action)) {
                fineInformation.setFineId(null);
            }
            processor.process(fineInformation);
            log.info(String.format("Fine %s action processed successfully: %s", action, message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s fine message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s fine message", action), e);
        }
    }

    private FineInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, FineInformation.class);
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