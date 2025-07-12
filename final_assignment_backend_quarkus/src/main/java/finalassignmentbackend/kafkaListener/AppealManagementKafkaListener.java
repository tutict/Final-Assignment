package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.service.AppealManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理申诉管理的消息
@ApplicationScoped
public class AppealManagementKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(AppealManagementKafkaListener.class.getName());

    // 注入申诉管理服务
    @Inject
    AppealManagementService appealManagementService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"appeal_create"主题的消息，处理申诉创建
    @Incoming("appeal_create")
    @Transactional
    @RunOnVirtualThread
    public void onAppealCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", appealManagementService::createAppeal);
    }

    // 监听"appeal_updated"主题的消息，处理申诉更新
    @Incoming("appeal_updated")
    @Transactional
    @RunOnVirtualThread
    public void onAppealUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", appealManagementService::updateAppeal);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<AppealManagement> processor) {
        try {
            // 反序列化消息为申诉管理对象
            AppealManagement appealManagement = deserializeMessage(message);
            log.log(Level.INFO, "反序列化申诉对象: {0}", appealManagement);
            // 对于创建操作，重置申诉ID
            if ("create".equals(action)) {
                appealManagement.setAppealId(null);
            }
            // 执行消息处理逻辑
            processor.process(appealManagement);
            log.info(String.format("申诉%s操作处理成功: %s", action, appealManagement));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s申诉消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s申诉消息", action), e);
        }
    }

    // 将消息反序列化为申诉管理对象
    private AppealManagement deserializeMessage(String message) {
        try {
            AppealManagement appeal = objectMapper.readValue(message, AppealManagement.class);
            // 验证申诉人姓名不为空
            if (appeal.getAppellantName() == null || appeal.getAppellantName().trim().isEmpty()) {
                log.log(Level.SEVERE, "反序列化的申诉对象姓名为空: {0}", message);
                throw new IllegalArgumentException("Kafka消息中的申诉人姓名不能为空");
            }
            return appeal;
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