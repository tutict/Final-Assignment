package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SystemSettings;
import finalassignmentbackend.service.SystemSettingsService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Acknowledgment;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class SystemSettingsKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(SystemSettingsKafkaListener.class);
    private final SystemSettingsService systemSettingsService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public SystemSettingsKafkaListener(SystemSettingsService systemSettingsService) {
        this.systemSettingsService = systemSettingsService;
    }

    @Incoming("system_settings_create")
    @Blocking
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