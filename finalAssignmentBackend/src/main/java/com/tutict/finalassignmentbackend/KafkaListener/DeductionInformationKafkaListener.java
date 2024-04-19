package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class DeductionInformationKafkaListener {

    private final DeductionInformationService deductionInformationService;

    @Autowired
    public DeductionInformationKafkaListener(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    @KafkaListener(topics = "deduction_command_topic", groupId = "deduction_group")
    public void onDeductionCommandReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 解析消息内容，确定扣款操作的类型和参数
            // 例如，这里可以根据消息内容创建一个扣款记录
            DeductionInformation deduction = parseDeductionCommand(message);
            deductionInformationService.createDeduction(deduction);

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing deduction command", e);
        }
    }

    private DeductionInformation parseDeductionCommand(String message) {
        // 实现消息内容解析逻辑，创建DeductionInformation对象
        // 这里只是一个示意，需要根据实际的消息格式来实现

        // 模拟返回一个DeductionInformation对象
        return new DeductionInformation();
    }
}
