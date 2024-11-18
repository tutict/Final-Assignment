package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.service.DeductionInformationService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


// 定义一个Kafka消息监听器类，用于处理扣款信息的创建和更新
@Component
public class DeductionInformationKafkaListener {

    // 初始化日志记录器
    private static final Logger log = LoggerFactory.getLogger(DeductionInformationKafkaListener.class);
    // 注入扣款信息服务
    private final DeductionInformationService deductionInformationService;
    // 初始化对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    // 构造函数，注入依赖的扣款信息服务
    @Autowired
    public DeductionInformationKafkaListener(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    // 监听扣款信息创建主题
    @KafkaListener(topics = "deduction_create", groupId = "deduction_listener_group", concurrency = "3")
    public void onDeductionCreateReceived(String message, Acknowledgment acknowledgment) {
        // 使用Vert.x的Future进行异步处理
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为DeductionInformation对象
                DeductionInformation deductionInformation = deserializeMessage(message);
                // 调用服务创建扣款信息
                deductionInformationService.createDeduction(deductionInformation);
                // 完成Promise，表示处理成功
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create deduction message: {}", message, e);
                // 失败时完成Promise
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 如果处理成功，则确认消息
                acknowledgment.acknowledge();
            } else {
                // 如果处理失败，则记录错误信息
                log.error("Error processing create deduction message: {}", message, res.cause());
            }
        });
    }

    // 监听扣款信息更新主题
    @KafkaListener(topics = "deduction_update", groupId = "deduction_listener_group", concurrency = "3")
    public void onDeductionUpdateReceived(String message, Acknowledgment acknowledgment) {
        // 使用Vert.x的Future进行异步处理
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为DeductionInformation对象
                DeductionInformation deductionInformation = deserializeMessage(message);

                // 根据业务逻辑处理更新扣款信息
                deductionInformationService.updateDeduction(deductionInformation);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update deduction message: {}", message, e);
                // 失败时完成Promise
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 如果处理成功，则确认消息
                acknowledgment.acknowledge();
            } else {
                // 如果处理失败，则记录错误信息
                log.error("Error processing update deduction message: {}", message, res.cause());
            }
        });
    }

    // 反序列化JSON消息为DeductionInformation对象
    private DeductionInformation deserializeMessage(String message) {
        try {
            // 使用ObjectMapper将JSON字符串转换为DeductionInformation对象
            return objectMapper.readValue(message, DeductionInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
