package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class FineInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(FineInformationKafkaListener.class);
    private final FineInformationService fineInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public FineInformationKafkaListener(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    @KafkaListener(topics = "fine_create", groupId = "fine_listener_group")
    public void onFineCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为FineInformation对象
            FineInformation fineInformation = deserializeMessage(message);

            // 根据业务逻辑处理创建罚款信息
            fineInformationService.createFine(fineInformation);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create fine message: {}", message, e);
        }
    }

    @KafkaListener(topics = "fine_update", groupId = "fine_listener_group")
    public void onFineUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为FineInformation对象
            FineInformation fineInformation = deserializeMessage(message);

            // 根据业务逻辑处理更新罚款信息
            fineInformationService.updateFine(fineInformation);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update fine message: {}", message, e);
        }
    }

    private FineInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到FineInformation对象的反序列化
        return objectMapper.readValue(message, FineInformation.class);
    }
}