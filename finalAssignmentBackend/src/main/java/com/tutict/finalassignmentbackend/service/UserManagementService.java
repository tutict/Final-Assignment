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
import java.util.concurrent.CompletableFuture;

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
    @CacheEvict(cacheNames = "userCache", allEntries = true, key = "#user.userId")
    public void createUser(UserManagement user) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, UserManagement>> future =  kafkaTemplate.send("user_create", user);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            userManagementMapper.insert(user);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
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
        if (username == null || username.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid username");
        }
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectOne(queryWrapper);
    }

    // 查询所有用户
    @Cacheable(cacheNames = "userCache")
    public List<UserManagement> getAllUsers() {
        UserManagement newUser = new UserManagement();
        if (userManagementMapper.selectCount(null) == 0) {
            newUser.setEmail(newUser.getEmail());
            newUser.setPassword(newUser.getPassword());
            createUser(newUser);
        }
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
        if (userType == null || userType.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid user type");
        }
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
        if (status == null || status.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid status");
        }
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", status);
        return userManagementMapper.selectList(queryWrapper);
    }

    // 更新用户
    @Transactional
    @CachePut(cacheNames = "userCache", key = "#user.userId")
    public void updateUser(UserManagement user) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, UserManagement>> future = kafkaTemplate.send("user_update", user);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            userManagementMapper.updateById(user);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 删除用户
     * @param userId 用户ID
     */
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
        }
    }

    /**
     * 根据用户名删除用户
     * @param username 用户名
     * @throws IllegalArgumentException 如果用户名无效
     */
    @CacheEvict(cacheNames = "userCache", key = "#username")
    public void deleteUserByUsername(String username) {
        try {
            UserManagement userToDelete = getUserByUsername(username);
            if (userToDelete != null) {
                userManagementMapper.delete(new QueryWrapper<UserManagement>().eq("username", username));
            }
        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while deleting user", e);
            // 抛出异常
            throw e;
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
        if (username == null || username.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid username");
        }
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectCount(queryWrapper) > 0;
    }

}
