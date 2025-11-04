package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.OffenseTypeDict;
import com.tutict.finalassignmentbackend.mapper.OffenseTypeDictMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class OffenseTypeDictKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseTypeDictKafkaListener.class.getName());

    private final OffenseTypeDictMapper offenseTypeDictMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public OffenseTypeDictKafkaListener(OffenseTypeDictMapper offenseTypeDictMapper, ObjectMapper objectMapper) {
        this.offenseTypeDictMapper = offenseTypeDictMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "offense_type_dict_create", groupId = "offenseTypeDictGroup", concurrency = "3")
    public void onOffenseTypeDictCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "offense_type_dict_update", groupId = "offenseTypeDictGroup", concurrency = "3")
    public void onOffenseTypeDictUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            OffenseTypeDict entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setTypeId(null);
                offenseTypeDictMapper.insert(entity);
            } else if ("update".equals(action)) {
                offenseTypeDictMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("OffenseTypeDict %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s OffenseTypeDict message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s OffenseTypeDict message", action), e);
        }
    }

    private OffenseTypeDict deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseTypeDict.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
