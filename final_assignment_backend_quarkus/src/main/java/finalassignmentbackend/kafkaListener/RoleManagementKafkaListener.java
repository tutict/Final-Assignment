package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.service.RoleManagementService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理角色管理的消息
@ApplicationScoped
public class RoleManagementKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(RoleManagementKafkaListener.class.getName());

    // 注入角色管理服务
    @Inject
    RoleManagementService roleManagementService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"role_create"主题的消息，处理角色创建
    @Incoming("role_create")
    @Transactional
    @RunOnVirtualThread
    public void onRoleCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", roleManagementService::createRole);
    }

    // 监听"role_update"主题的消息，处理角色更新
    @Incoming("role_update")
    @Transactional
    @RunOnVirtualThread
    public void onRoleUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", roleManagementService::updateRole);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<RoleManagement> processor) {
        try {
            // 反序列化消息为角色管理对象
            RoleManagement role = deserializeMessage(message);
            log.log(Level.INFO, "反序列化角色管理对象: {0}", role);
            // 对于创建操作，重置角色ID
            if ("create".equals(action)) {
                role.setRoleId(null);
            }
            // 执行消息处理逻辑
            processor.process(role);
            log.info(String.format("角色%s操作处理成功: %s", action, role));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s角色消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s角色消息", action), e);
        }
    }

    // 将消息反序列化为角色管理对象
    private RoleManagement deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, RoleManagement.class);
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