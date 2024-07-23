package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.OffenseInformationService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class OffenseInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(OffenseInformationKafkaListener.class);
    private final OffenseInformationService offenseInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public OffenseInformationKafkaListener(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    @Incoming("offense_create")
    @Blocking
    public void onOffenseCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OffenseInformation对象
                OffenseInformation offenseInformation = deserializeMessage(message);

                // 根据业务逻辑处理创建违法行为信息
                offenseInformationService.createOffense(offenseInformation);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create offense message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully create offense message: {}", message);
            } else {
                log.error("Error processing create offense message: {}", message, res.cause());
            }
        });
    }

    @Incoming("offense_update")
    @Blocking
    public void onOffenseUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OffenseInformation对象
                OffenseInformation offenseInformation = deserializeMessage(message);

                // 根据业务逻辑处理更新违法行为信息
                offenseInformationService.updateOffense(offenseInformation);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update offense message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully update offense message: {}", message);
            } else {
                log.error("Error processing update offense message: {}", message, res.cause());
            }
        });
    }

    private OffenseInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到OffenseInformation对象的反序列化
        return objectMapper.readValue(message, OffenseInformation.class);
    }
}