package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

// 定义一个Kafka消息监听器，用于处理车辆信息的创建和更新操作
@Component
public class VehicleInformationKafkaListener {

    // 初始化日志记录器
    private static final Logger log = LoggerFactory.getLogger(VehicleInformationKafkaListener.class);
    // 注入车辆信息业务服务
    private final VehicleInformationService vehicleInformationService;
    // 初始化对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    // 构造函数，自动注入车辆信息业务服务
    @Autowired
    public VehicleInformationKafkaListener(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    // 监听车辆创建主题，处理车辆创建消息
    @KafkaListener(topics = "vehicle_create", groupId = "vehicle_listener_group", concurrency = "3")
    public void onVehicleCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为VehicleInformation对象
                VehicleInformation vehicleInformation = deserializeMessage(message);

                // 根据业务逻辑处理创建车辆信息
                vehicleInformationService.createVehicleInformation(vehicleInformation);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create vehicle information message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge(); // 确认消息处理成功
            } else {
                log.error("Error processing create vehicle information message: {}", message, res.cause()); // 记录处理失败的错误信息
            }
        });
    }

    // 监听车辆更新主题，处理车辆更新消息
    @KafkaListener(topics = "vehicle_update", groupId = "vehicle_listener_group", concurrency = "3")
    public void onVehicleUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为VehicleInformation对象
                VehicleInformation vehicleInformation = deserializeMessage(message);

                // 根据业务逻辑处理更新车辆信息
                vehicleInformationService.updateVehicleInformation(vehicleInformation);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update vehicle information message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge(); // 确认消息处理成功
            } else {
                log.error("Error processing update vehicle information message: {}", message, res.cause()); // 记录处理失败的错误信息
            }
        });
    }

    // 将JSON字符串反序列化为VehicleInformation对象
    private VehicleInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, VehicleInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
