package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.service.VehicleInformationService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class VehicleInformationKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(VehicleInformationKafkaListener.class);
    private final VehicleInformationService vehicleInformationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public VehicleInformationKafkaListener(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    @Incoming("vehicle_create")
    @Blocking
    public void onVehicleCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为VehicleInformation对象
                VehicleInformation vehicleInformation = deserializeMessage(message);

                // 根据业务逻辑处理创建车辆信息
                vehicleInformationService.createVehicleInformation(vehicleInformation);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create vehicle information message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully create vehicle message: {}", message);
            } else {
                log.error("Error processing create vehicle information message: {}", message, res.cause());
            }
        });
    }

    @Incoming("vehicle_update")
    @Blocking
    public void onVehicleUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为VehicleInformation对象
                VehicleInformation vehicleInformation = deserializeMessage(message);

                // 根据业务逻辑处理更新车辆信息
                vehicleInformationService.updateVehicleInformation(vehicleInformation);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update vehicle information message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully update vehicle message: {}", message);
            } else {
                log.error("Error processing update vehicle information message: {}", message, res.cause());
            }
        });
    }

    private VehicleInformation deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到VehicleInformation对象的反序列化
        return objectMapper.readValue(message, VehicleInformation.class);
    }
}