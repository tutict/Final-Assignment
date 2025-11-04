package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SysDict;
import com.tutict.finalassignmentbackend.mapper.SysDictMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class SysDictKafkaListener {

    private static final Logger log = Logger.getLogger(SysDictKafkaListener.class.getName());

    private final SysDictMapper sysDictMapper;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysDictKafkaListener(SysDictMapper sysDictMapper, ObjectMapper objectMapper) {
        this.sysDictMapper = sysDictMapper;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "sys_dict_create", groupId = "sysDictGroup", concurrency = "3")
    public void onSysDictCreateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for create: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "create"));
    }

    @KafkaListener(topics = "sys_dict_update", groupId = "sysDictGroup", concurrency = "3")
    public void onSysDictUpdateReceived(String message) {
        log.log(Level.INFO, "Received Kafka message for update: {0}", message);
        Thread.ofVirtual().start(() -> processMessage(message, "update"));
    }

    private void processMessage(String message, String action) {
        try {
            SysDict entity = deserializeMessage(message);
            if ("create".equals(action)) {
                entity.setDictId(null);
                sysDictMapper.insert(entity);
            } else if ("update".equals(action)) {
                sysDictMapper.updateById(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return;
            }
            log.info(String.format("SysDict %s action processed successfully: %s", action, entity));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysDict message: %s", action, message), e);
            throw new RuntimeException(String.format("Failed to process %s SysDict message", action), e);
        }
    }

    private SysDict deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SysDict.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: {0}", message);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}
