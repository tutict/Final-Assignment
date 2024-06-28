package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.FineInformation;
import finalassignmentbackend.service.FineInformationService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Acknowledgment;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class FineInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(FineInformationKafkaListener.class);
    private final FineInformationService fineInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public FineInformationKafkaListener(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }

    @Incoming("fine_create")
    @Blocking
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

    @Incoming("fine_update")
    @Blocking
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

    private FineInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到FineInformation对象的反序列化
        return objectMapper.readValue(message, FineInformation.class);
    }
}