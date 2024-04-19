package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DriverInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(DriverInformationKafkaListener.class);
    private final DriverInformationService driverInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public DriverInformationKafkaListener(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    @KafkaListener(topics = "driver_create", groupId = "driver_listener_group")
    public void onDriverCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为DriverInformation对象
            DriverInformation driverInformation = deserializeMessage(message);

            driverInformationService.createDriver(driverInformation);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create driver message: {}", message, e);
        }
    }

    @KafkaListener(topics = "driver_update", groupId = "driver_listener_group")
    public void onDriverUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为DriverInformation对象
            DriverInformation driverInformation = deserializeMessage(message);

            // 根据业务逻辑处理更新驾驶员信息
            driverInformationService.updateDriver(driverInformation);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update driver message: {}", message, e);
        }
    }

    private DriverInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到DriverInformation对象的反序列化
        return objectMapper.readValue(message, DriverInformation.class);
    }
}