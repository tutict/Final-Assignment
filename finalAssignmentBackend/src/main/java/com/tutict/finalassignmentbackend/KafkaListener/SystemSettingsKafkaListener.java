package com.tutict.finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.SystemSettings;
import com.tutict.finalassignmentbackend.service.SystemSettingsService;
import io.vertx.core.Future;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

@Component
public class SystemSettingsKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(SystemSettingsKafkaListener.class);
    private final SystemSettingsService systemSettingsService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public SystemSettingsKafkaListener(SystemSettingsService systemSettingsService) {
        this.systemSettingsService = systemSettingsService;
    }

    @KafkaListener(topics = "system_settings_update", groupId = "system_settings_listener_group")
    public void onSystemSettingsUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为SystemSettings对象
                SystemSettings systemSettings = deserializeMessage(message);

                // 根据业务逻辑处理更新系统设置
                systemSettingsService.updateSystemSettings(systemSettings);
                // 这里通常不需要再次保存数据库，因为更新操作已经在产生消息的服务层完成

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update system settings message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update system settings message: {}", message, res.cause());
            }
        });
    }

    private SystemSettings deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到SystemSettings对象的反序列化
        return objectMapper.readValue(message, SystemSettings.class);
    }
}