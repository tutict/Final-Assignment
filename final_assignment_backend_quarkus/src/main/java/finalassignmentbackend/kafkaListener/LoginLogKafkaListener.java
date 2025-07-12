package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.service.LoginLogService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理登录日志的消息
@ApplicationScoped
public class LoginLogKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(LoginLogKafkaListener.class.getName());

    // 注入登录日志服务
    @Inject
    LoginLogService loginLogService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"login_create"主题的消息，处理登录日志创建
    @Incoming("login_create")
    @Transactional
    @RunOnVirtualThread
    public void onLoginLogCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", loginLogService::createLoginLog);
    }

    // 监听"login_update"主题的消息，处理登录日志更新
    @Incoming("login_update")
    @Transactional
    @RunOnVirtualThread
    public void onLoginLogUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", loginLogService::updateLoginLog);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<LoginLog> processor) {
        try {
            // 反序列化消息为登录日志对象
            LoginLog loginLog = deserializeMessage(message);
            log.log(Level.INFO, "反序列化登录日志对象: {0}", loginLog);
            // 对于创建操作，重置日志ID
            if ("create".equals(action)) {
                loginLog.setLogId(null);
            }
            // 执行消息处理逻辑
            processor.process(loginLog);
            log.info(String.format("登录日志%s操作处理成功: %s", action, loginLog));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s登录日志消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s登录日志消息", action), e);
        }
    }

    // 将消息反序列化为登录日志对象
    private LoginLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, LoginLog.class);
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