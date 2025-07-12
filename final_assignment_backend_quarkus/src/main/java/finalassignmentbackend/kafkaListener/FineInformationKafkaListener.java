package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.FineInformation;
import finalassignmentbackend.service.FineInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理罚款信息的消息
@ApplicationScoped
public class FineInformationKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(FineInformationKafkaListener.class.getName());

    // 注入罚款信息服务
    @Inject
    FineInformationService fineInformationService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"fine_create"主题的消息，处理罚款信息创建
    @Incoming("fine_create")
    @Transactional
    @RunOnVirtualThread
    public void onFineCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", fineInformationService::createFine);
    }

    // 监听"fine_update"主题的消息，处理罚款信息更新
    @Incoming("fine_update")
    @Transactional
    @RunOnVirtualThread
    public void onFineUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", fineInformationService::updateFine);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<FineInformation> processor) {
        try {
            // 反序列化消息为罚款信息对象
            FineInformation fineInformation = deserializeMessage(message);
            log.log(Level.INFO, "反序列化罚款信息对象: {0}", fineInformation);
            // 对于创建操作，重置罚款ID
            if ("create".equals(action)) {
                fineInformation.setFineId(null);
            }
            // 执行消息处理逻辑
            processor.process(fineInformation);
            log.info(String.format("罚款%s操作处理成功: %s", action, fineInformation));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s罚款消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s罚款消息", action), e);
        }
    }

    // 将消息反序列化为罚款信息对象
    private FineInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, FineInformation.class);
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