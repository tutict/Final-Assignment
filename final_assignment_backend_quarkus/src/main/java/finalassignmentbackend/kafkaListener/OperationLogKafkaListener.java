package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.service.OperationLogService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理操作日志的消息
@ApplicationScoped
public class OperationLogKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(OperationLogKafkaListener.class.getName());

    // 注入操作日志服务
    @Inject
    OperationLogService operationLogService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"operation_create"主题的消息，处理操作日志创建
    @Incoming("operation_create")
    @Transactional
    @RunOnVirtualThread
    public void onOperationLogCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", operationLogService::createOperationLog);
    }

    // 监听"operation_update"主题的消息，处理操作日志更新
    @Incoming("operation_update")
    @Transactional
    @RunOnVirtualThread
    public void onOperationLogUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", operationLogService::updateOperationLog);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<OperationLog> processor) {
        try {
            // 反序列化消息为操作日志对象
            OperationLog operationLog = deserializeMessage(message);
            log.log(Level.INFO, "反序列化操作日志对象: {0}", operationLog);
            // 对于创建操作，重置日志ID
            if ("create".equals(action)) {
                operationLog.setLogId(null);
            }
            // 执行消息处理逻辑
            processor.process(operationLog);
            log.info(String.format("操作日志%s操作处理成功: %s", action, operationLog));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s操作日志消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s操作日志消息", action), e);
        }
    }

    // 将消息反序列化为操作日志对象
    private OperationLog deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OperationLog.class);
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