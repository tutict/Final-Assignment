package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SystemSettings;
import finalassignmentbackend.service.SystemSettingsService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理系统设置的消息
@ApplicationScoped
public class SystemSettingsKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(SystemSettingsKafkaListener.class.getName());

    // 注入系统设置服务
    @Inject
    SystemSettingsService systemSettingsService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"system_settings_update"主题的消息，处理系统设置更新
    @Incoming("system_settings_update")
    @Transactional
    @RunOnVirtualThread
    public void onSystemSettingsUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", systemSettingsService::updateSystemSettings);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<SystemSettings> processor) {
        try {
            // 反序列化消息为系统设置对象
            SystemSettings systemSettings = deserializeMessage(message);
            log.log(Level.INFO, "反序列化系统设置对象: {0}", systemSettings);
            // 执行消息处理逻辑
            processor.process(systemSettings);
            log.info(String.format("系统设置%s操作处理成功: %s", action, systemSettings));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s系统设置消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s系统设置消息", action), e);
        }
    }

    // 将消息反序列化为系统设置对象
    private SystemSettings deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, SystemSettings.class);
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