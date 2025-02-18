package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.UserManagementMapper;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.logging.Logger;

@Service
public class UserManagementService {

    private static final Logger log = Logger.getLogger(UserManagementService.class.getName());

    private final UserManagementMapper userManagementMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, UserManagement> kafkaTemplate;

    @Autowired
    public UserManagementService(UserManagementMapper userManagementMapper,
                                 RequestHistoryMapper requestHistoryMapper,
                                 KafkaTemplate<String, UserManagement> kafkaTemplate) {
        this.userManagementMapper = userManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "userCache", allEntries = true)
    @WsAction(service = "UserManagementService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, UserManagement user, String action) {
        // Query request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // Insert a "PROCESSING" status if not found
        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        // Notify Kafka or local events to create the user
        sendKafkaMessage(user, action);

        Integer userId = user.getUserId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(userId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "userCache", allEntries = true)
    public void createUser(UserManagement user) {
        try {
            userManagementMapper.insert(user);
            Integer userId = user.getUserId();
            log.info(String.format("User created successfully, userId=%d", userId));
        } catch (Exception e) {
            log.warning("Exception occurred while creating user: " + e.getMessage());
            throw new RuntimeException("Failed to create user", e);
        }
    }

    @Cacheable(cacheNames = "userCache")
    @WsAction(service = "UserManagementService", action = "getUserById")
    public UserManagement getUserById(Integer userId) {
        if (userId == null || userId <= 0 || userId >= Integer.MAX_VALUE) {
            throw new RuntimeException("Invalid userId" + userId);
        }
        return userManagementMapper.selectById(userId);
    }

    @Cacheable(cacheNames = "userCache")
    @WsAction(service = "UserManagementService", action = "getUserByUsername")
    public UserManagement getUserByUsername(String username) {
        validateInput(username, "Invalid username");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectOne(queryWrapper);
    }

    @Cacheable(cacheNames = "userCache")
    @WsAction(service = "UserManagementService", action = "getAllUsers")
    public List<UserManagement> getAllUsers() {
        return userManagementMapper.selectList(null);
    }

    @Cacheable(cacheNames = "userCache")
    @WsAction(service = "UserManagementService", action = "getUsersByType")
    public List<UserManagement> getUsersByType(String userType) {
        validateInput(userType, "Invalid user type");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", userType);
        return userManagementMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "userCache")
    @WsAction(service = "UserManagementService", action = "getUsersByStatus")
    public List<UserManagement> getUsersByStatus(String status) {
        validateInput(status, "Invalid status");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", status);
        return userManagementMapper.selectList(queryWrapper);
    }

    @Transactional
    @CacheEvict(cacheNames = "userCache", allEntries = true)
    public void updateUser(UserManagement user) {
        try {
            userManagementMapper.updateById(user);
        } catch (Exception e) {
            log.warning("Exception occurred while updating user or firing event");
            throw new RuntimeException("Failed to update user", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "userCache", allEntries = true)
    @WsAction(service = "UserManagementService", action = "deleteUser")
    public void deleteUser(int userId) {
        try {
            UserManagement userToDelete = userManagementMapper.selectById(userId);
            if (userToDelete != null) {
                userManagementMapper.deleteById(userId);
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting user");
            throw new RuntimeException("Failed to delete user", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "userCache", allEntries = true)
    @WsAction(service = "UserManagementService", action = "deleteUserByUsername")
    public void deleteUserByUsername(String username) {
        validateInput(username, "Invalid username");
        try {
            QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
            queryWrapper.eq("username", username);
            UserManagement userToDelete = userManagementMapper.selectOne(queryWrapper);
            if (userToDelete != null) {
                userManagementMapper.delete(queryWrapper);
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting user");
            throw new RuntimeException("Failed to delete user", e);
        }
    }

    @Cacheable(cacheNames = "usernameExistsCache")
    @WsAction(service = "UserManagementService", action = "isUsernameExists")
    public boolean isUsernameExists(String username) {
        validateInput(username, "Invalid username");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectCount(queryWrapper) > 0;
    }

    private void sendKafkaMessage(UserManagement user, String action) {
        String topic = action.equals("create") ? "user_create" : "user_update";
        kafkaTemplate.send(topic, user);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}