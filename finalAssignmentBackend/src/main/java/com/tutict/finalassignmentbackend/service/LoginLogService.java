package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.LoginLogDocument;
import com.tutict.finalassignmentbackend.mapper.LoginLogMapper;
import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.LoginLogSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class LoginLogService {

    private static final Logger log = Logger.getLogger(LoginLogService.class.getName());

    private final LoginLogMapper loginLogMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final LoginLogSearchRepository loginLogSearchRepository;
    private final KafkaTemplate<String, LoginLog> kafkaTemplate;

    @Autowired
    public LoginLogService(LoginLogMapper loginLogMapper,
                           RequestHistoryMapper requestHistoryMapper,
                           LoginLogSearchRepository loginLogSearchRepository,
                           KafkaTemplate<String, LoginLog> kafkaTemplate) {
        this.loginLogMapper = loginLogMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.loginLogSearchRepository = loginLogSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "loginCache", allEntries = true)
    @WsAction(service = "LoginLogService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, LoginLog loginLog, String action) {
        // 查询 request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
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
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        sendKafkaMessage("login_" + action, loginLog);

        Integer loginLogId = loginLog.getLogId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(loginLogId != null ? loginLogId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "loginCache", allEntries = true)
    public void createLoginLog(LoginLog loginLog) {
        LoginLog existingLog = loginLogMapper.selectById(loginLog.getLogId());
        if (existingLog == null) {
            loginLogMapper.insert(loginLog);
        } else {
            loginLogMapper.updateById(loginLog);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "loginCache", allEntries = true)
    public void updateLoginLog(LoginLog loginLog) {
        LoginLog existingLog = loginLogMapper.selectById(loginLog.getLogId());
        if (existingLog == null) {
            loginLogMapper.insert(loginLog);
        } else {
            loginLogMapper.updateById(loginLog);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "loginCache", allEntries = true)
    @WsAction(service = "LoginLogService", action = "deleteLoginLog")
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

    @Cacheable(cacheNames = "loginCache")
    @WsAction(service = "LoginLogService", action = "getLoginLog")
    public LoginLog getLoginLog(Integer logId) {
        if (logId == null || logId <= 0 || logId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid log ID" + logId);
        }
        return loginLogMapper.selectById(logId);
    }

    @Cacheable(cacheNames = "loginCache")
    @WsAction(service = "LoginLogService", action = "getAllLoginLogs")
    public List<LoginLog> getAllLoginLogs() {
        return loginLogMapper.selectList(null);
    }

    @Cacheable(cacheNames = "loginCache")
    @WsAction(service = "LoginLogService", action = "getLoginLogsByTimeRange")
    public List<LoginLog> getLoginLogsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("login_time", startTime, endTime);
        return loginLogMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "loginCache")
    @WsAction(service = "LoginLogService", action = "getLoginLogsByUsername")
    public List<LoginLog> getLoginLogsByUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid username");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return loginLogMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "loginCache")
    @WsAction(service = "LoginLogService", action = "getLoginLogsByLoginResult")
    public List<LoginLog> getLoginLogsByLoginResult(String loginResult) {
        if (loginResult == null || loginResult.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid login result");
        }
        QueryWrapper<LoginLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("login_result", loginResult);
        return loginLogMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "loginLogCache", unless = "#result.isEmpty()")
    public List<String> getUsernamesByPrefixGlobally(String prefix) {
        validateInput(prefix, "Invalid username prefix");
        log.log(Level.INFO, "Fetching username suggestions for prefix: {0}", new Object[]{prefix});

        try {
            SearchHits<LoginLogDocument> searchHits = loginLogSearchRepository
                    .searchByUsernameGlobally(prefix);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(LoginLogDocument::getUsername)
                    .filter(Objects::nonNull)
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "Found {0} username suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "Error fetching username suggestions for prefix {0}: {1}",
                    new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    @Cacheable(cacheNames = "loginLogCache", unless = "#result.isEmpty()")
    public List<String> getLoginResultsByPrefixGlobally(String prefix) {
        validateInput(prefix, "Invalid login result prefix");
        log.log(Level.INFO, "Fetching login result suggestions for prefix: {0}", new Object[]{prefix});

        try {
            SearchHits<LoginLogDocument> searchHits = loginLogSearchRepository
                    .searchByLoginResultFuzzyGlobally(prefix);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(LoginLogDocument::getLoginResult)
                    .filter(Objects::nonNull)
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "Found {0} login result suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "Error fetching login result suggestions for prefix {0}: {1}",
                    new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }

    private void sendKafkaMessage(String topic, LoginLog loginLog) {
        kafkaTemplate.send(topic, loginLog);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}