package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.UserManagementDocument;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.UserManagementMapper;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.repository.UserManagementSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class UserManagementService {

    private static final Logger log = Logger.getLogger(UserManagementService.class.getName());

    private final UserManagementMapper userManagementMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final UserManagementSearchRepository userManagementSearchRepository;
    private final KafkaTemplate<String, UserManagement> kafkaTemplate;

    @Autowired
    public UserManagementService(UserManagementMapper userManagementMapper,
                                 RequestHistoryMapper requestHistoryMapper,
                                 UserManagementSearchRepository userManagementSearchRepository,
                                 KafkaTemplate<String, UserManagement> kafkaTemplate) {
        this.userManagementMapper = userManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.userManagementSearchRepository = userManagementSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = {"userCache", "usernameExistsCache"}, allEntries = true)
    @WsAction(service = "UserManagementService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, UserManagement user, String action) {
        log.info(String.format("检查幂等性密钥: %s，操作: %s", idempotencyKey, action));
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("检测到重复请求 (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("检测到重复请求");
        }

        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
            sendKafkaMessage(user, action);
            Integer userId = user.getUserId();
            newRequest.setBusinessStatus("SUCCESS");
            newRequest.setBusinessId(userId != null ? userId.longValue() : null);
            requestHistoryMapper.updateById(newRequest);
            log.info(String.format("幂等性记录插入成功: %s", idempotencyKey));
        } catch (Exception e) {
            log.severe("插入幂等性记录失败: idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("重复请求或数据库插入错误", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = {"userCache", "usernameExistsCache"}, allEntries = true)
    @WsAction(service = "UserManagementService", action = "checkAndInsertIdempotency")
    public void createUser(UserManagement user) {
        try {
            userManagementMapper.insert(user);
            Integer userId = user.getUserId();
            log.info(String.format("用户创建成功，userId=%d", userId));
            // 同步到 Elasticsearch
            UserManagementDocument doc = new UserManagementDocument();
            doc.setUsername(user.getUsername());
            doc.setStatus(user.getStatus());
            doc.setContactNumber(user.getContactNumber());
            userManagementSearchRepository.save(doc);
        } catch (Exception e) {
            log.warning("创建用户时发生异常: " + e.getMessage());
            throw new RuntimeException("创建用户失败", e);
        }
    }

    @Cacheable(cacheNames = "userCache", unless = "#result == null")
    @WsAction(service = "UserManagementService", action = "getUserById")
    public UserManagement getUserById(Integer userId) {
        if (userId == null || userId <= 0 || userId >= Integer.MAX_VALUE) {
            throw new RuntimeException("无效的 userId: " + userId);
        }
        UserManagement user = userManagementMapper.selectById(userId);
        if (user == null) {
            log.warning(String.format("未找到用户，ID: %d", userId));
        }
        return user;
    }

    @Cacheable(cacheNames = "userCache", unless = "#result == null")
    @WsAction(service = "UserManagementService", action = "getUserByUsername")
    public UserManagement getUserByUsername(String username) {
        validateInput(username, "无效的用户名");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        UserManagement user = userManagementMapper.selectOne(queryWrapper);
        if (user == null) {
            log.warning(String.format("未找到用户，用户名: %s", username));
        }
        return user;
    }

    @Cacheable(cacheNames = "userCache", unless = "#result == null || #result.isEmpty()")
    @WsAction(service = "UserManagementService", action = "getAllUsers")
    public List<UserManagement> getAllUsers() {
        List<UserManagement> users = userManagementMapper.selectList(null);
        if (users.isEmpty()) {
            log.warning("系统中未找到用户");
        }
        return users;
    }

    @Cacheable(cacheNames = "userCache", unless = "#result == null || #result.isEmpty()")
    @WsAction(service = "UserManagementService", action = "getUsersByRole")
    public List<UserManagement> getUsersByRole(String roleName) {
        validateInput(roleName, "无效的角色名称");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.inSql("user_id",
                "SELECT user_id FROM user_role WHERE role_id IN " +
                        "(SELECT role_id FROM role_management WHERE role_name = '" + roleName + "')");
        List<UserManagement> users = userManagementMapper.selectList(queryWrapper);
        if (users.isEmpty()) {
            log.warning(String.format("未找到角色为 %s 的用户", roleName));
        }
        return users;
    }

    @Cacheable(cacheNames = "userCache", unless = "#result == null || #result.isEmpty()")
    @WsAction(service = "UserManagementService", action = "getUsersByStatus")
    public List<UserManagement> getUsersByStatus(String status) {
        validateInput(status, "无效的状态");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", status);
        List<UserManagement> users = userManagementMapper.selectList(queryWrapper);
        if (users.isEmpty()) {
            log.warning(String.format("未找到状态为 %s 的用户", status));
        }
        return users;
    }

    @Transactional
    @CacheEvict(cacheNames = {"userCache", "usernameExistsCache"}, allEntries = true)
    public void updateUser(UserManagement user) {
        try {
            userManagementMapper.updateById(user);
            user.setModifiedTime(LocalDateTime.now());
            // 同步到 Elasticsearch
            UserManagementDocument doc = new UserManagementDocument();
            doc.setUsername(user.getUsername());
            doc.setStatus(user.getStatus());
            doc.setContactNumber(user.getContactNumber());
            userManagementSearchRepository.save(doc);
        } catch (Exception e) {
            log.warning("更新用户时发生异常: " + e.getMessage());
            throw new RuntimeException("更新用户失败", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = {"userCache", "usernameExistsCache"}, allEntries = true)
    public void deleteUser(int userId) {
        try {
            UserManagement userToDelete = userManagementMapper.selectById(userId);
            if (userToDelete != null) {
                userManagementMapper.deleteById(userId);
            }
        } catch (Exception e) {
            log.warning("删除用户时发生异常: " + e.getMessage());
            throw new RuntimeException("删除用户失败", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = {"userCache", "usernameExistsCache"}, allEntries = true)
    @WsAction(service = "UserManagementService", action = "deleteUserByUsername")
    public void deleteUserByUsername(String username) {
        validateInput(username, "无效的用户名");
        try {
            QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
            queryWrapper.eq("username", username);
            UserManagement userToDelete = userManagementMapper.selectOne(queryWrapper);
            if (userToDelete != null) {
                userManagementMapper.delete(queryWrapper);
            }
        } catch (Exception e) {
            log.warning("删除用户时发生异常: " + e.getMessage());
            throw new RuntimeException("删除用户失败", e);
        }
    }

    @Cacheable(cacheNames = "usernameExistsCache", unless = "#result == null")
    @WsAction(service = "UserManagementService", action = "isUsernameExists")
    public boolean isUsernameExists(String username) {
        validateInput(username, "无效的用户名");
        log.log(Level.WARNING, "检查用户名是否存在: {}", username);
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        Long count = userManagementMapper.selectCount(queryWrapper);
        log.log(Level.WARNING, "用户名 {0} 存在: {1}", new Object[]{username, count > 0});
        return count > 0;
    }

    @Cacheable(cacheNames = "userCache", unless = "#result.isEmpty()")
    public List<String> getUsernamesByPrefixGlobally(String prefix) {
        validateInput(prefix, "无效的用户名前缀");
        log.log(Level.INFO, "获取用户名建议，前缀: {0}", new Object[]{prefix});

        try {
            SearchHits<UserManagementDocument> searchHits = userManagementSearchRepository
                    .searchByUsernameGlobally(prefix);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(UserManagementDocument::getUsername)
                    .filter(Objects::nonNull)
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "找到 {0} 个用户名建议，前缀: {1}", new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "获取用户名建议失败，前缀 {0}: {1}", new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    @Cacheable(cacheNames = "userCache", unless = "#result.isEmpty()")
    public List<String> getStatusesByPrefixGlobally(String prefix) {
        validateInput(prefix, "Invalid status prefix");
        log.log(Level.INFO, "Fetching status suggestions for prefix: {0}", new Object[]{prefix});

        try {
            SearchHits<UserManagementDocument> searchHits = userManagementSearchRepository
                    .searchByStatusGlobally(prefix);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(UserManagementDocument::getStatus)
                    .filter(Objects::nonNull)
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "Found {0} status suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "Error fetching status suggestions for prefix {0}: {1}",
                    new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    @Cacheable(cacheNames = "userCache", unless = "#result.isEmpty()")
    public List<String> getPhoneNumbersByPrefixGlobally(String prefix) {
        validateInput(prefix, "Invalid phone number prefix");
        log.log(Level.INFO, "Fetching phone number suggestions for prefix: {0}", new Object[]{prefix});

        try {
            SearchHits<UserManagementDocument> searchHits = userManagementSearchRepository
                    .searchByPhoneNumberGlobally(prefix);
            List<String> suggestions = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(UserManagementDocument::getContactNumber)
                    .filter(Objects::nonNull)
                    .distinct()
                    .limit(10)
                    .collect(Collectors.toList());

            log.log(Level.INFO, "Found {0} phone number suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), prefix});
            return suggestions.isEmpty() ? Collections.emptyList() : suggestions;
        } catch (Exception e) {
            log.log(Level.WARNING, "Error fetching phone number suggestions for prefix {0}: {1}",
                    new Object[]{prefix, e.getMessage()});
            return Collections.emptyList();
        }
    }

    private void sendKafkaMessage(UserManagement user, String action) {
        String topic = action.equals("create") ? "user_create" : "user_update";
        kafkaTemplate.send(topic, user);
        log.info(String.format("消息成功发送到 Kafka 主题 %s", topic));
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}