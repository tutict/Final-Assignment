package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.mapper.LoginLogMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.logging.Logger;

@ApplicationScoped
public class LoginLogService {

    private static final Logger log = Logger.getLogger(LoginLogService.class.getName());

    @Inject
    LoginLogMapper loginLogMapper;

    @Inject
    @Channel("login-events-out")
    MutinyEmitter<LoginLog> loginEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "loginCache")
    public void createLoginLog(LoginLog loginLog) {
        try {
            sendKafkaMessage("login_create", loginLog);
            loginLogMapper.insert(loginLog);
        } catch (Exception e) {
            log.info("Exception occurred while creating login log or sending Kafka message");
            throw new RuntimeException("Failed to create login log", e);
        }
    }

    @CacheResult(cacheName = "loginCache")
    public LoginLog getLoginLog(int logId) {
        return loginLogMapper.selectById(logId);
    }

    @CacheResult(cacheName = "loginCache")
    public List<LoginLog> getAllLoginLogs() {
        return loginLogMapper.selectList(null);
    }

    @Transactional
    @CacheInvalidate(cacheName = "loginCache")
    public void updateLoginLog(LoginLog loginLog) {
        try {
            sendKafkaMessage("login_update", loginLog);
            loginLogMapper.updateById(loginLog);
        } catch (Exception e) {
            log.warning("Exception occurred while updating login log or sending Kafka message");
            throw new RuntimeException("Failed to update login log", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "loginCache")
    public void deleteLoginLog(int logId) {
        try {
            int result = loginLogMapper.deleteById(logId);
            if (result > 0) {
                log.info(String.format("Login log with ID %s deleted successfully", logId));
            } else {
                log.severe(String.format("Failed to delete login log with ID %s", logId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting login log");
            throw new RuntimeException("Failed to delete login log", e);
        }
    }

    @CacheResult(cacheName = "loginCache")
    public List<LoginLog> getLoginLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("login_time", startTime, endTime);
        return loginLogMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "loginCache")
    public List<LoginLog> getLoginLogsByUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid username");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return loginLogMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "loginCache")
    public List<LoginLog> getLoginLogsByLoginResult(String loginResult) {
        if (loginResult == null || loginResult.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid login result");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("login_result", loginResult);
        return loginLogMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, LoginLog loginLog) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<LoginLog> message = Message.of(loginLog).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = loginEmitter.sendMessage(message);

        // 将 Uni<Void> 转换为 CompletionStage<Void>
        CompletionStage<Void> sendStage = uni.subscribe().asCompletionStage();

        sendStage.whenComplete((ignored, throwable) -> {
            if (throwable != null) {
                log.severe(String.format("Failed to send message to Kafka topic %s: %s", topic, throwable.getMessage()));
            } else {
                log.info(String.format("Message sent to Kafka topic %s successfully", topic));
            }
        });
    }
}
