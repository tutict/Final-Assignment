package finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.OffenseInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.util.logging.Level;
import java.util.logging.Logger;

// Kafka监听器类，用于处理违章信息的消息
@ApplicationScoped
public class OffenseInformationKafkaListener {

    // 日志记录器，用于记录处理过程中的信息
    private static final Logger log = Logger.getLogger(OffenseInformationKafkaListener.class.getName());

    // 注入违章信息服务
    @Inject
    OffenseInformationService offenseInformationService;

    // 注入JSON对象映射器
    @Inject
    ObjectMapper objectMapper;

    // 监听"offense_create"主题的消息，处理违章信息创建
    @Incoming("offense_create")
    @Transactional
    @RunOnVirtualThread
    public void onOffenseCreateReceived(String message) {
        log.log(Level.INFO, "收到Kafka创建消息: {0}", message);
        processMessage(message, "create", offenseInformationService::createOffense);
    }

    // 监听"offense_update"主题的消息，处理违章信息更新
    @Incoming("offense_update")
    @Transactional
    @RunOnVirtualThread
    public void onOffenseUpdateReceived(String message) {
        log.log(Level.INFO, "收到Kafka更新消息: {0}", message);
        processMessage(message, "update", offenseInformationService::updateOffense);
    }

    // 处理Kafka消息的通用方法
    private void processMessage(String message, String action, MessageProcessor<OffenseInformation> processor) {
        try {
            // 反序列化消息为违章信息对象
            OffenseInformation offenseInformation = deserializeMessage(message);
            log.log(Level.INFO, "反序列化违章信息对象: {0}", offenseInformation);
            // 对于创建操作，重置违章ID
            if ("create".equals(action)) {
                offenseInformation.setOffenseId(null);
            }
            // 执行消息处理逻辑
            processor.process(offenseInformation);
            log.info(String.format("违章%s操作处理成功: %s", action, offenseInformation));
        } catch (Exception e) {
            // 记录处理错误日志
            log.log(Level.SEVERE, String.format("处理%s违章消息时出错: %s", action, message), e);
            throw new RuntimeException(String.format("无法处理%s违章消息", action), e);
        }
    }

    // 将消息反序列化为违章信息对象
    private OffenseInformation deserializeMessage(String message) {
        try {
            return objectMapper.readValue(message, OffenseInformation.class);
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