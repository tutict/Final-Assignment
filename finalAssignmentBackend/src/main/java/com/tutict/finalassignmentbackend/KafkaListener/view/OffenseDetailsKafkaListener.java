package com.tutict.finalassignmentbackend.KafkaListener.view;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import com.tutict.finalassignmentbackend.service.view.OffenseDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class OffenseDetailsKafkaListener {

    private final OffenseDetailsService offenseDetailsService;

    @Autowired
    public OffenseDetailsKafkaListener(OffenseDetailsService offenseDetailsService) {
        this.offenseDetailsService = offenseDetailsService;
    }

    @KafkaListener(topics = "offense_details_topic", groupId = "offense_details_group")
    public void onOffenseDetailsReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为OffenseDetails对象
            OffenseDetails offenseDetails = deserializeMessage(message);

            // 处理收到的OffenseDetails对象，例如保存到数据库
            offenseDetailsService.saveOffenseDetails(offenseDetails);

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，选择不确认消息，以便Kafka重新投递
        }
    }

    private OffenseDetails deserializeMessage(String message) {
        try {
            // 实现JSON字符串到OffenseDetails对象的反序列化
            ObjectMapper objectMapper = new ObjectMapper();
            return objectMapper.readValue(message, OffenseDetails.class);
        } catch (Exception e) {
            // 异常处理，例如日志记录
            // log.error("Error deserializing message", e);
            return null;
        }
    }
}
