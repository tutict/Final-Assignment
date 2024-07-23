package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.DeductionInformation;
import finalassignmentbackend.service.DeductionInformationService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class DeductionInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(DeductionInformationKafkaListener.class);
    private final DeductionInformationService deductionInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public DeductionInformationKafkaListener(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }

    @Incoming("deduction_create")
    @Blocking
    public void onDeductionCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为DeductionInformation对象
                DeductionInformation deductionInformation = deserializeMessage(message);
                deductionInformationService.createDeduction(deductionInformation);
                promise.complete();
            } catch (Exception e) {
                log.error("Error processing create deduction message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully create deduction message: {}", message);
            } else {
                log.error("Error processing create deduction message: {}", message, res.cause());
            }
        });
    }

    @Incoming("deduction_update")
    @Blocking
    public void onDeductionUpdateReceived(String message) {
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
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully update deduction message: {}", message);
            } else {
                log.error("Error processing update deduction message: {}", message, res.cause());
            }
        });
    }

    private DeductionInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到DeductionInformation对象的反序列化
        return objectMapper.readValue(message, DeductionInformation.class);
    }
}