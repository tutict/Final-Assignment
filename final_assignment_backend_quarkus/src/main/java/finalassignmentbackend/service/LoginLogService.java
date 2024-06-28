package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.LoginLogMapper;
import finalassignmentbackend.entity.LoginLog;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;
import java.util.List;

@ApplicationScoped
public class LoginLogService {

    private static final Logger log = LoggerFactory.getLogger(LoginLogService.class);

    @Inject
    LoginLogMapper loginLogMapper;

    @Inject
    @Channel("login_create")
    Emitter<LoginLog> loginCreateEmitter;

    @Inject
    @Channel("login_update")
    Emitter<LoginLog> loginUpdateEmitter;

    @Transactional
    public void createLoginLog(LoginLog loginLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            loginCreateEmitter.send(loginLog).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            loginLogMapper.insert(loginLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public LoginLog getLoginLog(int logId) {
        return loginLogMapper.selectById(logId);
    }

    public List<LoginLog> getAllLoginLogs() {
        return loginLogMapper.selectList(null);
    }

    @Transactional
    public void updateLoginLog(LoginLog loginLog) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            loginCreateEmitter.send(loginLog).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            loginLogMapper.updateById(loginLog);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public void deleteLoginLog(int logId) {
        loginLogMapper.deleteById(logId);
    }

    // getLoginLogsByTimeRange
    public List<LoginLog> getLoginLogsByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("login_time", startTime, endTime);
        return loginLogMapper.selectList(queryWrapper);
    }

    // getLoginLogsByUsername
    public List<LoginLog> getLoginLogsByUsername(String username) {
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return loginLogMapper.selectList(queryWrapper);
    }

    // getLoginLogsByLoginResult
    public List<LoginLog> getLoginLogsByLoginResult(String loginResult) {
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("login_result", loginResult);
        return loginLogMapper.selectList(queryWrapper);
    }
}
