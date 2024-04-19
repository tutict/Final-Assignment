package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

@Component
public class VehicleInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(VehicleInformationKafkaListener.class);
    private final VehicleInformationService vehicleInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public VehicleInformationKafkaListener(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    @KafkaListener(topics = "vehicle_create", groupId = "vehicle_listener_group")
    public void onVehicleCreateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为VehicleInformation对象
            VehicleInformation vehicleInformation = deserializeMessage(message);

            // 根据业务逻辑处理创建车辆信息
            vehicleInformationService.createVehicleInformation(vehicleInformation);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing create vehicle information message: {}", message, e);
        }
    }

    @KafkaListener(topics = "vehicle_update", groupId = "vehicle_listener_group")
    public void onVehicleUpdateReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为VehicleInformation对象
            VehicleInformation vehicleInformation = deserializeMessage(message);

            // 根据业务逻辑处理更新车辆信息
            vehicleInformationService.updateVehicleInformation(vehicleInformation);

            // 确认消息已被成功处理
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 记录异常信息，不确认消息，以便Kafka重新投递
            log.error("Error processing update vehicle information message: {}", message, e);
        }
    }

    private VehicleInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到VehicleInformation对象的反序列化
        return objectMapper.readValue(message, VehicleInformation.class);
    }
}