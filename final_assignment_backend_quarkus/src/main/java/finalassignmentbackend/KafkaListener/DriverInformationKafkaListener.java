package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.service.DriverInformationService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Acknowledgment;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class DriverInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(DriverInformationKafkaListener.class);
    private final DriverInformationService driverInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public DriverInformationKafkaListener(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    @Incoming("driver_create")
    @Blocking
    public void onDriverCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为DriverInformation对象
                DriverInformation driverInformation = deserializeMessage(message);

                driverInformationService.createDriver(driverInformation);
                promise.complete();

            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create driver message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 确认消息已被成功处理
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create driver message: {}", message, res.cause());
            }
        });
    }

    @Incoming("driver_update")
    @Blocking
    public void onDriverUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为DriverInformation对象
                DriverInformation driverInformation = deserializeMessage(message);

                // 根据业务逻辑处理更新驾驶员信息
                driverInformationService.updateDriver(driverInformation);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update driver message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 确认消息已被成功处理
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update driver message: {}", message, res.cause());
            }
        });
    }

    private DriverInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到DriverInformation对象的反序列化
        return objectMapper.readValue(message, DriverInformation.class);
    }
}