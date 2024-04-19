package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.service.AppealManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class AppealManagementKafkaListener {

    private final AppealManagementService appealManagementService;

    @Autowired
    public AppealManagementKafkaListener(AppealManagementService appealManagementService) {
        this.appealManagementService = appealManagementService;
    }

    @KafkaListener(topics = "your_kafka_topic", groupId = "group_id")
    public void onAppealReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为AppealManagement对象
            AppealManagement appealManagement = deserializeMessage(message);

            // 处理收到的AppealManagement对象，例如保存到数据库
            appealManagementService.createAppeal(appealManagement);

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing message", e);
        }
    }

    private AppealManagement deserializeMessage(String message) {
        // 实现JSON字符串到AppealManagement对象的反序列化
        // 这里需要一个合适的JSON转换器，例如Jackson的ObjectMapper
        // ObjectMapper objectMapper = new ObjectMapper();
        // return objectMapper.readValue(message, AppealManagement.class);

        // 模拟反序列化过程，实际应用中需要替换为上述代码
        return new AppealManagement();
    }
}