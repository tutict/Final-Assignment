package finalassignmentbackend.KafkaListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.service.UserManagementService;
import io.smallrye.reactive.messaging.annotations.Blocking;
import io.vertx.core.Future;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ApplicationScoped
public class UserManagementKafkaListener {

    private static final Logger log = LoggerFactory.getLogger(UserManagementKafkaListener.class);
    private final UserManagementService userManagementService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject
    public UserManagementKafkaListener(UserManagementService userManagementService) {
        this.userManagementService = userManagementService;
    }

    @Incoming("user_create")
    @Blocking
    public void onUserCreateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为UserManagement对象
                UserManagement user = deserializeMessage(message);

                // 根据业务逻辑处理创建用户
                userManagementService.createUser(user);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing create user message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully create user message: {}", message);
            } else {
                log.error("Error processing create user message: {}", message, res.cause());
            }
        });
    }

    @Incoming("user_update")
    @Blocking
    public void onUserUpdateReceived(String message) {
        Future.<Void>future(promise -> {
            try {
                // 反序列化消息内容为UserManagement对象
                UserManagement user = deserializeMessage(message);

                // 根据业务逻辑处理更新用户
                userManagementService.updateUser(user);

                // 确认消息已被成功处理
                promise.complete();
            } catch (Exception e) {
                // 记录异常信息，不确认消息，以便Kafka重新投递
                log.error("Error processing update user message: {}", message, e);
                promise.fail(e);
            }
        }).onComplete(res -> {
            if (res.succeeded()) {
                log.info("Successfully update user message: {}", message);
            } else {
                log.error("Error processing update user message: {}", message, res.cause());
            }
        });
    }

    private UserManagement deserializeMessage(String message) throws JsonProcessingException {
        // 实现JSON字符串到UserManagement对象的反序列化
        return objectMapper.readValue(message, UserManagement.class);
    }
}