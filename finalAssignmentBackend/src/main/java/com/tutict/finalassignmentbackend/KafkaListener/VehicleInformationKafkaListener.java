package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class VehicleInformationKafkaListener {

    @Autowired
    public VehicleInformationKafkaListener(VehicleInformationService vehicleInformationService) {
    }

    @KafkaListener(topics = "vehicle_management_topic", groupId = "vehicle_management_group")
    public void onVehicleInformationReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为VehicleInformation对象
            VehicleInformation vehicleInformation = deserializeMessage(message);

            // 根据业务需求处理接收到的车辆信息变更事件，例如更新相关依赖的车辆数据
            // 这里可以添加自定义的业务逻辑处理代码

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing vehicle information", e);
        }
    }

    private VehicleInformation deserializeMessage(String message) {
        // 实现JSON字符串到VehicleInformation对象的反序列化
        // 这里需要一个合适的JSON转换器，例如Jackson的ObjectMapper
        // ObjectMapper objectMapper = new ObjectMapper();
        // return objectMapper.readValue(message, VehicleInformation.class);

        // 模拟反序列化过程，实际应用中需要替换为上述代码
        return new VehicleInformation();
    }
}