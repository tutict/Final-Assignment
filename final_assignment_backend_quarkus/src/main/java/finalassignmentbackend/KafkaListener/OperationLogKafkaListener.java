package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OperationLog;
import finalassignmentbackend.service.OperationLogService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class OperationLogKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(OperationLogKafkaListener.class);
    private final OperationLogService operationLogService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public OperationLogKafkaListener(OperationLogService operationLogService) {
        this.operationLogService = operationLogService;
    }

    @Incoming("operation_create")
    @Blocking
    public void onOperationLogCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OperationLog对象
                OperationLog operationLog = deserializeMessage(message);

                // 根据业务逻辑处理创建操作日志
                operationLogService.createOperationLog(operationLog);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create operation log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully create operation log message: {}", message);
            } else {
                log.error("Error processing create operation log message: {}", message, res.cause());
            }
        });
    }

    @Incoming("operation_update")
    @Blocking
    public void onOperationLogUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OperationLog对象
                OperationLog operationLog = deserializeMessage(message);

                // 根据业务逻辑处理更新操作日志
                operationLogService.updateOperationLog(operationLog);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update operation log message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully update operation log message: {}", message);
            } else {
                log.error("Error processing update operation log message: {}", message, res.cause());
            }
        });
    }

    private OperationLog deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到OperationLog对象的反序列化
        return objectMapper.readValue(message, OperationLog.class);
    }
}