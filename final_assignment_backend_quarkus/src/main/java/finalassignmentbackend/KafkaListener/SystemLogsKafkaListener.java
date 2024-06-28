package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.SystemLogs;
import finalassignmentbackend.service.SystemLogsService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Acknowledgment;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class SystemLogsKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(SystemLogsKafkaListener.class);
    private final SystemLogsService systemLogsService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public SystemLogsKafkaListener(SystemLogsService systemLogsService) {
        this.systemLogsService = systemLogsService;
    }

    @Incoming("system_update")
    @Blocking
    public void onSystemLogCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为SystemLogs对象
                SystemLogs systemLog = deserializeMessage(message);

                // 根据业务逻辑处理创建系统日志
                systemLogsService.createSystemLog(systemLog);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create system log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create system log message: {}", message, res.cause());
            }
        });
    }

    @Incoming("system_create")
    @Blocking
    public void onSystemLogUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为SystemLogs对象
                SystemLogs systemLog = deserializeMessage(message);

                // 根据业务逻辑处理更新系统日志
                systemLogsService.updateSystemLog(systemLog);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update system log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update system log message: {}", message, res.cause());
            }
    });
    }

    private SystemLogs deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到SystemLogs对象的反序列化
        return objectMapper.readValue(message, SystemLogs.class);
    }
}