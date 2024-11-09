package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.UserManagementMapper;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class UserManagementService {

    private static final Logger log = LoggerFactory.getLogger(UserManagementService.class);

    private final UserManagementMapper userManagementMapper;
    private final KafkaTemplate<String, UserManagement> kafkaTemplate;

    @Autowired
    public UserManagementService(UserManagementMapper userManagementMapper, KafkaTemplate<String, UserManagement> kafkaTemplate) {
        this.userManagementMapper = userManagementMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建用户
    @Transactional
    @CacheEvict(cacheNames = "userCache", key = "#user.userId")
    public void createUser(UserManagement user) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("user_create", user);
            // 插入用户到数据库
            userManagementMapper.insert(user);
        } catch (Exception e) {
            // 记录异常
            log.error("Exception occurred while creating user or sending Kafka message", e);
            throw new RuntimeException("Failed to create user", e);
        }
    }

    // 根据用户ID查询用户
    @Cacheable(cacheNames = "userCache", key = "#userId")
    public UserManagement getUserById(int userId) {
        return userManagementMapper.selectById(userId);
    }

    /**
     * 根据用户名查询用户
     * @param username 用户名
     * @return 用户对象
     * @throws IllegalArgumentException 如果用户名无效
     */
    @Cacheable(cacheNames = "userCache", key = "#username")
    public UserManagement getUserByUsername(String username) {
        validateInput(username, "Invalid username");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectOne(queryWrapper);
    }

    // 查询所有用户
    @Cacheable(cacheNames = "userCache", key = "'allUsers'")
    public List<UserManagement> getAllUsers() {
        return userManagementMapper.selectList(null);
    }

    /**
     * 根据用户类型查询用户
     * @param userType 用户类型
     * @return 用户对象列表
     * @throws IllegalArgumentException 如果用户类型无效
     */
    @Cacheable(cacheNames = "userCache", key = "#userType")
    public List<UserManagement> getUsersByType(String userType) {
        validateInput(userType, "Invalid user type");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", userType);
        return userManagementMapper.selectList(queryWrapper);
    }

    /**
     * 根据用户状态查询用户
     * @param status 用户状态
     * @return 用户对象列表
     * @throws IllegalArgumentException 如果用户状态无效
     */
    @Cacheable(cacheNames = "userCache", key = "#status")
    public List<UserManagement> getUsersByStatus(String status) {
        validateInput(status, "Invalid status");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", status);
        return userManagementMapper.selectList(queryWrapper);
    }

    // 更新用户
    @Transactional
    @CachePut(cacheNames = "userCache", key = "#user.userId")
    public void updateUser(UserManagement user) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("user_update", user);
            // 更新数据库中的用户信息
            userManagementMapper.updateById(user);
        } catch (Exception e) {
            // 记录异常
            log.error("Exception occurred while updating user or sending Kafka message", e);
            throw new RuntimeException("Failed to update user", e);
        }
    }

    /**
     * 删除用户
     * @param userId 用户ID
     */
    @Transactional
    @CacheEvict(cacheNames = "userCache", key = "#userId")
    public void deleteUser(int userId) {
        try {
            UserManagement userToDelete = userManagementMapper.selectById(userId);
            if (userToDelete != null) {
                userManagementMapper.deleteById(userId);
            }
        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while deleting user", e);
            throw new RuntimeException("Failed to delete user", e);
        }
    }

    /**
     * 根据用户名删除用户
     * @param username 用户名
     * @throws IllegalArgumentException 如果用户名无效
     */
    @Transactional
    @CacheEvict(cacheNames = "userCache", key = "#username")
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
            log.error("Exception occurred while deleting user", e);
            throw new RuntimeException("Failed to delete user", e);
        }
    }

    /**
     * 检查用户名是否存在
     * @param username 用户名
     * @return 如果用户名存在就true否则就false
     * @throws IllegalArgumentException 如果用户名无效
     */
    @Cacheable(cacheNames = "userCache", key = "#username")
    public boolean isUsernameExists(String username) {
        validateInput(username, "Invalid username");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectCount(queryWrapper) > 0;
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, UserManagement user) throws Exception {
        SendResult<String, UserManagement> sendResult = kafkaTemplate.send(topic, user).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }

    // 校验输入数据
    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}
