package com.tutict.finalassignmentbackend.KafkaListener.view;

import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import com.tutict.finalassignmentbackend.service.view.OffenseDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class OffenseDetailsKafkaListener {

    @Autowired
    public OffenseDetailsKafkaListener(OffenseDetailsService offenseDetailsService) {
    }

    @KafkaListener(topics = "offense_details_topic", groupId = "offense_details_group")
    public void onOffenseDetailsReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为OffenseDetails对象
            // 假设消息是以JSON格式发送的，需要将字符串反序列化为对象
            OffenseDetails offenseDetails = deserializeMessage(message);

            // 处理收到的OffenseDetails对象，例如保存到数据库
            // 这里可以根据业务逻辑来决定是保存、更新还是其他操作
            // 例如：offenseDetailsService.saveOffenseDetails(offenseDetails);

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing message", e);
        }
    }

    private OffenseDetails deserializeMessage(String message) {
        // 实现JSON字符串到OffenseDetails对象的反序列化
        // 这里需要一个合适的JSON转换器，例如Jackson的ObjectMapper
        // ObjectMapper objectMapper = new ObjectMapper();
        // return objectMapper.readValue(message, OffenseDetails.class);

        // 模拟反序列化过程，实际应用中需要替换为上述代码
        return new OffenseDetails();
    }
}