package com.tutict.finalassignmentbackend.kafkaListener.view;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import com.tutict.finalassignmentbackend.service.view.OffenseDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
public class OffenseDetailsKafkaListener {

    private static final Logger log = Logger.getLogger(OffenseDetailsKafkaListener.class.getName());

    private final OffenseDetailsService offenseDetailsService;
    private final ObjectMapper objectMapper;

    @Autowired
    public OffenseDetailsKafkaListener(OffenseDetailsService offenseDetailsService, ObjectMapper objectMapper) {
        this.offenseDetailsService = offenseDetailsService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "offense_details_topic", groupId = "offenseDetailsGroup")
    @Transactional
    public void onOffenseDetailsReceived(String message) {
        try {
            OffenseDetails offenseDetails = deserializeMessage(message);
            offenseDetailsService.saveOffenseDetails(offenseDetails);
            log.info(String.format("Successfully processed offense details message: %s", message));
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing offense details message: %s", message), e);
            throw new RuntimeException("Failed to process offense details message", e);
        }
    }

    private OffenseDetails deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseDetails.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to deserialize message: " + message, e);
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
}