package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.service.VehicleInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理车辆信息的消息
@ApplicationScoped
public class VehicleInformationKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(VehicleInformationKafkaListener.class.getName());

    // 注入车辆信息服务
    @Inject
    VehicleInformationService vehicleInformationService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"vehicle_create"主题的消息，处理车辆信息创建
    @Incoming("vehicle_create")
    @Transactional
    @RunOnVirtualThread
    public void onVehicleCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", vehicleInformationService::createVehicleInformation);
    }

    // 监听"vehicle_update"主题的消息，处理车辆信息更新
    @Incoming("vehicle_update")
    @Transactional
    @RunOnVirtualThread
    public void onVehicleUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", vehicleInformationService::updateVehicleInformation);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<VehicleInformation> processor) {
        try {
            // 反序列化消息为车辆信息对象
            VehicleInformation vehicleInformation = deserializeMessage(message);
            log.log(Level.INFO, "反序列化车辆信息对象: {0}", vehicleInformation);
            // 对于创建操作，重置车辆ID
            if ("create".equals(action)) {
                vehicleInformation.setVehicleId(null);
            }
            // 执行消息处理逻辑
            processor.process(vehicleInformation);
            log.info(String.format("车辆%s操作处理成功: %s", action, vehicleInformation));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s车辆信息消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s车辆信息消息", action), e);
        }
    }

    // 将消息反序列化为车辆信息对象
    private VehicleInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, VehicleInformation.class);
        } catch (Exception e) {
            // 记录反序列化错误日志
            log.log(Level.SEVERE, "反序列化消息失败: {0}", message);
            throw new RuntimeException("反序列化消息失败", e);
        }
    }

    // 函数式接口，用于定义消息处理逻辑
    @FunctionalInterface
    private interface MessageProcessor<T> {
        void process(T t) throws Exception;
    }
}