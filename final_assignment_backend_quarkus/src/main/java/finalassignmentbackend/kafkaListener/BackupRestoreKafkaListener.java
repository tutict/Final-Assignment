package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.service.BackupRestoreService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理备份和恢复的消息
@ApplicationScoped
public class BackupRestoreKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(BackupRestoreKafkaListener.class.getName());

    // 注入备份和恢复服务
    @Inject
    BackupRestoreService backupRestoreService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"backup_create"主题的消息，处理备份创建
    @Incoming("backup_create")
    @Transactional
    @RunOnVirtualThread
    public void onBackupCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", backupRestoreService::createBackup);
    }

    // 监听"backup_update"主题的消息，处理备份更新
    @Incoming("backup_update")
    @Transactional
    @RunOnVirtualThread
    public void onBackupUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", backupRestoreService::updateBackup);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<BackupRestore> processor) {
        try {
            // 反序列化消息为备份和恢复对象
            BackupRestore backupRestore = deserializeMessage(message);
            log.log(Level.INFO, "反序列化备份对象: {0}", backupRestore);
            // 对于创建操作，重置备份ID
            if ("create".equals(action)) {
                backupRestore.setBackupId(null);
            }
            // 执行消息处理逻辑
            processor.process(backupRestore);
            log.info(String.format("备份%s操作处理成功: %s", action, backupRestore));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s备份消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s备份消息", action), e);
        }
    }

    // 将消息反序列化为备份和恢复对象
    private BackupRestore deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, BackupRestore.class);
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