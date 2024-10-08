package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.service.FineInformationService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;


// 定义一个Kafka消息监听器，用于处理罚款信息的相关消息
@Component
public class FineInformationKafkaListener {

    // 初始化日志记录器
    private static final Logger log = LoggerFactory.getLogger(FineInformationKafkaListener.class);
    // 注入罚款信息服务
    private final FineInformationService fineInformationService;
    // 初始化一个对象映射器，用于JSON序列化和反序列化
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    // 构造函数，初始化罚款信息服务
    @Autowired
    public FineInformationKafkaListener(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    // 监听罚款创建消息的主题
    @KafkaListener(topics = "fine_create", groupId = "fine_listener_group", concurrency = "3")
    public void onFineCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为FineInformation对象
                FineInformation fineInformation = deserializeMessage(message);

                // 根据业务逻辑处理创建罚款信息
                fineInformationService.createFine(fineInformation);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create fine message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create fine message: {}", message, res.cause());
            }
        });
    }

    // 监听罚款更新消息的主题
    @KafkaListener(topics = "fine_update", groupId = "fine_listener_group", concurrency = "3")
    public void onFineUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为FineInformation对象
                FineInformation fineInformation = deserializeMessage(message);

                // 根据业务逻辑处理更新罚款信息
                fineInformationService.updateFine(fineInformation);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update fine message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update fine message: {}", message, res.cause());
            }
        });
    }

    // 反序列化JSON消息为FineInformation对象
    private FineInformation deserializeMessage(String message) {
        try {
            // 实现JSON字符串到FineInformation对象的反序列化
            return objectMapper.readValue(message, FineInformation.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
