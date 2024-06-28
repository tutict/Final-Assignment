package finalassignmentbackend.KafkaListener.view;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.view.OffenseDetails;
import finalassignmentbackend.service.view.OffenseDetailsService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Acknowledgment;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class OffenseDetailsKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(OffenseDetailsKafkaListener.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final OffenseDetailsService offenseDetailsService;

    @Inject
    public OffenseDetailsKafkaListener(OffenseDetailsService offenseDetailsService) {
        this.offenseDetailsService = offenseDetailsService;
    }

    @Incoming("offense_details_topic")
    @Blocking
    public void onOffenseDetailsReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为OffenseDetails对象
                OffenseDetails offenseDetails = deserializeMessage(message);

                // 处理收到的OffenseDetails对象，例如保存到数据库
                offenseDetailsService.saveOffenseDetails(offenseDetails);

                // 确认消息处理成功
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing appeal message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                // 消息处理成功，确认消息处理成功
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing appeal message: {}", message, res.cause());
            }
        });
    }

    private OffenseDetails deserializeMessage(String message) throws JsonProcessingException {
        return objectMapper.readValue(message, OffenseDetails.class);
    }
}
