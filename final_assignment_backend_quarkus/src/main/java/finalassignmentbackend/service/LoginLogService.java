package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.mapper.LoginLogMapper;
import finalassignmentbackend.mapper.RequestHistoryMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Event;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.TransactionPhase;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Getter;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class LoginLogService {

    private static final Logger log = Logger.getLogger(LoginLogService.class.getName());

    @Inject
    LoginLogMapper loginLogMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<LoginLogEvent> loginLogEvent;

    @Inject
    @Channel("login-events-out")
    MutinyEmitter<LoginLog> loginEmitter;

    @Getter
    public static class LoginLogEvent {
        private final LoginLog loginLog;
        private final String action; // "create" or "update"

        public LoginLogEvent(LoginLog loginLog, String action) {
            this.loginLog = loginLog;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "userCache")
    public void checkAndInsertIdempotency(String idempotencyKey, LoginLog loginLog, String action) {
        // 查询 request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            // 已有此 key -> 重复请求
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // 不存在 -> 插入一条 PROCESSING
        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            // 若并发下同 key 导致唯一索引冲突
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        loginLogEvent.fire(new LoginLogService.LoginLogEvent(loginLog, action));

        Integer loginLogId = loginLog.getLogId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(loginLogId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheInvalidate(cacheName = "loginCache")
    public void createLoginLog(LoginLog loginLog) {
        LoginLog existingLog = loginLogMapper.selectById(loginLog.getLogId());
        if (existingLog == null) {
            loginLogMapper.insert(loginLog);
        } else {
            loginLogMapper.updateById(loginLog);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "loginCache")
    public void updateLoginLog(LoginLog loginLog) {
        LoginLog existingLog = loginLogMapper.selectById(loginLog.getLogId());
        if (existingLog == null) {
            loginLogMapper.insert(loginLog);
        } else {
            loginLogMapper.updateById(loginLog);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "loginCache")
    public void deleteLoginLog(int logId) {
        if (logId <= 0) {
            throw new IllegalArgumentException("Invalid log ID");
        }
        int result = loginLogMapper.deleteById(logId);
        if (result > 0) {
            log.info(String.format("Login log with ID %s deleted successfully", logId));
        } else {
            log.severe(String.format("Failed to delete login log with ID %s", logId));
        }
    }

    @CacheResult(cacheName = "loginCache")
    public LoginLog getLoginLog(int logId) {
        if (logId <= 0) {
            throw new IllegalArgumentException("Invalid log ID");
        }
        return loginLogMapper.selectById(logId);
    }

    @CacheResult(cacheName = "loginCache")
    public List<LoginLog> getAllLoginLogs() {
        return loginLogMapper.selectList(null);
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

    public void onLoginLogEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) LoginLogEvent event) {
        String topic = event.getAction().equals("create") ? "login_processed_create" : "login_processed_update";
        sendKafkaMessage(topic, event.getLoginLog());
    }

    private void sendKafkaMessage(String topic, LoginLog loginLog) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<LoginLog> message = Message.of(loginLog).addMetadata(metadata);

        loginEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
