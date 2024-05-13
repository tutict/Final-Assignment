package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


@Component
public class DeductionInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(DeductionInformationKafkaListener.class);
    private final DeductionInformationService deductionInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public DeductionInformationKafkaListener(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    @KafkaListener(topics = "deduction_create", groupId = "deduction_listener_group")
    public void onDeductionCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为DeductionInformation对象
            DeductionInformation deductionInformation = deserializeMessage(message);

            deductionInformationService.createDeduction(deductionInformation);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create deduction message: {}", message, e);
        }
    }

    @KafkaListener(topics = "deduction_update", groupId = "deduction_listener_group")
    public void onDeductionUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为DeductionInformation对象
            DeductionInformation deductionInformation = deserializeMessage(message);

            // 根据业务逻辑处理更新扣款信息
            deductionInformationService.updateDeduction(deductionInformation);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update deduction message: {}", message, e);
        }
    }

    private DeductionInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到DeductionInformation对象的反序列化
        return objectMapper.readValue(message, DeductionInformation.class);
    }
}