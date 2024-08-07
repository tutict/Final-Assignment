package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.service.RoleManagementService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class RoleManagementKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(RoleManagementKafkaListener.class);
    private final RoleManagementService roleManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public RoleManagementKafkaListener(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }

    @Incoming("role_create")
    @Blocking
    public void onRoleCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为RoleManagement对象
                RoleManagement role = deserializeMessage(message);

                // 根据业务逻辑处理创建角色
                roleManagementService.createRole(role);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create role message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.info("Successfully create role message: {}", message);
            } else {
                log.error("Error processing create role message: {}", message, res.cause());
            }
        });
    }

    @Incoming("role_update")
    @Blocking
    public void onRoleUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为RoleManagement对象
                RoleManagement role = deserializeMessage(message);

                // 根据业务逻辑处理更新角色
                roleManagementService.updateRole(role);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update role message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.failed()) {
                log.info("Successfully update role message: {}", message);
            } else {
                log.error("Error processing update role message: {}", message, res.cause());
            }
        });
    }

    private RoleManagement deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到RoleManagement对象的反序列化
        return objectMapper.readValue(message, RoleManagement.class);
    }
}