package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class DriverInformationKafkaListener {

    private final DriverInformationService driverInformationService;

    @Autowired
    public DriverInformationKafkaListener(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    @KafkaListener(topics = "driver_update_topic", groupId = "driver_group")
    public void onDriverUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为DriverInformation对象
            DriverInformation driverInformation = deserializeMessage(message);

            // 根据消息类型处理更新，例如更新驾驶员信息
            driverInformationService.updateDriver(driverInformation);

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing driver update", e);
        }
    }

    private DriverInformation deserializeMessage(String message) {
        // 实现JSON字符串到DriverInformation对象的反序列化
        // 这里需要一个合适的JSON转换器，例如Jackson的ObjectMapper
        // ObjectMapper objectMapper = new ObjectMapper();
        // return objectMapper.readValue(message, DriverInformation.class);

        // 模拟反序列化过程，实际应用中需要替换为上述代码
        return new DriverInformation();
    }
}
