package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.mapper.LoginLogMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class LoginLogService {

    private static final Logger log = Logger.getLogger(String.valueOf(LoginLogService.class));

    @Inject
    LoginLogMapper loginLogMapper;

    @Inject
    @Channel("login-events-out")
    Emitter<LoginLog> loginEmitter;

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
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, LoginLog> record = (KafkaRecord<String, LoginLog>) KafkaRecord.of(loginLog.getLogId().toString(), loginLog).addMetadata(metadata);
        loginEmitter.send(record);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
