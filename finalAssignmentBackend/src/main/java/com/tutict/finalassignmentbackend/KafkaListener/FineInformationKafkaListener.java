package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class FineInformationKafkaListener {

    private final FineInformationService fineInformationService;

    @Autowired
    public FineInformationKafkaListener(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    @KafkaListener(topics = "fine_update_topic", groupId = "fine_group")
    public void onFineUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为FineInformation对象
            FineInformation fineInformation = deserializeMessage(message);

            // 根据消息类型处理更新，例如更新罚款信息
            fineInformationService.updateFine(fineInformation);

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing fine update", e);
        }
    }

    private FineInformation deserializeMessage(String message) {
        // 实现JSON字符串到FineInformation对象的反序列化
        // 这里需要一个合适的JSON转换器，例如Jackson的ObjectMapper
        // ObjectMapper objectMapper = new ObjectMapper();
        // return objectMapper.readValue(message, FineInformation.class);

        // 模拟反序列化过程，实际应用中需要替换为上述代码
        return new FineInformation();
    }
}