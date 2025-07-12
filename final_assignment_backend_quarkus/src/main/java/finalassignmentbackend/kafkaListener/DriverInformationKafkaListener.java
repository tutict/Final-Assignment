package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.service.DriverInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理驾驶员信息的消息
@ApplicationScoped
public class DriverInformationKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(DriverInformationKafkaListener.class.getName());

    // 注入驾驶员信息服务
    @Inject
    DriverInformationService driverInformationService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"driver_create"主题的消息，处理驾驶员信息创建
    @Incoming("driver_create")
    @Transactional
    @RunOnVirtualThread
    public void onDriverCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", driverInformationService::createDriver);
    }

    // 监听"driver_update"主题的消息，处理驾驶员信息更新
    @Incoming("driver_update")
    @Transactional
    @RunOnVirtualThread
    public void onDriverUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", driverInformationService::updateDriver);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<DriverInformation> processor) {
        try {
            // 反序列化消息为驾驶员信息对象
            DriverInformation driverInformation = deserializeMessage(message);
            log.log(Level.INFO, "反序列化驾驶员信息对象: {0}", driverInformation);
            // 对于创建操作，重置驾驶员ID
            if ("create".equals(action)) {
                driverInformation.setDriverId(null);
            }
            // 执行消息处理逻辑
            processor.process(driverInformation);
            log.info(String.format("驾驶员%s操作处理成功: %s", action, driverInformation));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s驾驶员消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s驾驶员消息", action), e);
        }
    }

    // 将消息反序列化为驾驶员信息对象
    private DriverInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, DriverInformation.class);
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