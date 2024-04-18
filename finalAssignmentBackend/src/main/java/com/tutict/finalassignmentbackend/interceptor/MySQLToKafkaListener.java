package com.tutict.finalassignmentbackend.interceptor;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.sql.ResultSet;
import java.sql.SQLException;

@Component
public class MySQLToKafkaListener {

    private final JdbcTemplate jdbcTemplate;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public MySQLToKafkaListener(JdbcTemplate jdbcTemplate, KafkaTemplate<String, String> kafkaTemplate, ObjectMapper objectMapper) {
        this.jdbcTemplate = jdbcTemplate;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void init() {
        jdbcTemplate.query("SELECT * FROM your_table_name", this::processRow);
    }

    private void processRow(ResultSet rs) throws SQLException {
        // Convert ResultSet to a POJO or JSON string
        // For example:
        YourDataModel dataModel = new YourDataModel();
        dataModel.setId(rs.getInt("id"));
        dataModel.setName(rs.getString("name"));
        // Convert dataModel to JSON string
        String jsonData = objectMapper.writeValueAsString(dataModel);

        // Send the JSON string to Kafka topic
        kafkaTemplate.send("your_kafka_topic", jsonData);
    }
}
