package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.PermissionManagement;
import finalassignmentbackend.service.PermissionManagementService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Acknowledgment;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class PermissionManagementKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(PermissionManagementKafkaListener.class);
    private final PermissionManagementService permissionManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public PermissionManagementKafkaListener(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }

    @Incoming("permission_create")
    @Blocking
    public void onPermissionCreateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为PermissionManagement对象
                PermissionManagement permission = deserializeMessage(message);

                // 根据业务逻辑处理创建权限
                permissionManagementService.createPermission(permission);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create permission message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing create permission message: {}", message, res.cause());
            }
        });
    }

    @Incoming("permission_update")
    @Blocking
    public void onPermissionUpdateReceived(String message, Acknowledgment acknowledgment) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为PermissionManagement对象
                PermissionManagement permission = deserializeMessage(message);

                // 根据业务逻辑处理更新权限
                permissionManagementService.updatePermission(permission);

                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update permission message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                acknowledgment.acknowledge();
            } else {
                log.error("Error processing update permission message: {}", message, res.cause());
            }
        });
    }

    private PermissionManagement deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到PermissionManagement对象的反序列化
        return objectMapper.readValue(message, PermissionManagement.class);
    }
}