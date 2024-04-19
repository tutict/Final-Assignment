package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class OffenseInformationKafkaListener {

    private final OffenseInformationService offenseInformationService;

    @Autowired
    public OffenseInformationKafkaListener(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    @KafkaListener(topics = "offense_update_topic", groupId = "offense_group")
    public void onOffenseUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为OffenseInformation对象
            OffenseInformation offenseInformation = deserializeMessage(message);

            // 根据消息类型处理更新，例如更新违法行为信息
            offenseInformationService.updateOffense(offenseInformation);

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing offense update", e);
        }
    }

    private OffenseInformation deserializeMessage(String message) {
        // 实现JSON字符串到OffenseInformation对象的反序列化
        // 这里需要一个合适的JSON转换器，例如Jackson的ObjectMapper
        // ObjectMapper objectMapper = new ObjectMapper();
        // return objectMapper.readValue(message, OffenseInformation.class);

        // 模拟反序列化过程，实际应用中需要替换为上述代码
        return new OffenseInformation();
    }
}