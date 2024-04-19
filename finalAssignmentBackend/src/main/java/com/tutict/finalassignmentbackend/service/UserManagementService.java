package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.UserManagementMapper;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserManagementService {

    private final UserManagementMapper userManagementMapper;
    private final KafkaTemplate<String, UserManagement> kafkaTemplate;

    @Autowired
    public UserManagementService(UserManagementMapper userManagementMapper, KafkaTemplate<String, UserManagement> kafkaTemplate) {
        this.userManagementMapper = userManagementMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建用户
    public void createUser(UserManagement user) {
        // 发送用户创建信息到 Kafka 主题
        kafkaTemplate.send("user_create", user);
        userManagementMapper.insert(user);
    }

    // 根据用户ID查询用户
    public UserManagement getUserById(int userId) {
        return userManagementMapper.selectById(userId);
    }

    // 根据用户名查询用户
    public UserManagement getUserByUsername(String username) {
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectOne(queryWrapper);
    }

    // 查询所有用户
    public List<UserManagement> getAllUsers() {
        return userManagementMapper.selectList(null);
    }

    // 根据用户类型查询用户
    public List<UserManagement> getUsersByType(String userType) {
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", userType);
        return userManagementMapper.selectList(queryWrapper);
    }

    // 根据用户状态查询用户
    public List<UserManagement> getUsersByStatus(String status) {
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", status);
        return userManagementMapper.selectList(queryWrapper);
    }

    // 更新用户
    public void updateUser(UserManagement user) {
        // 发送用户更新信息到 Kafka 主题
        kafkaTemplate.send("user_update", user);
        userManagementMapper.updateById(user);
    }

    // 删除用户
    public void deleteUser(int userId) {
        UserManagement userToDelete = userManagementMapper.selectById(userId);
        if (userToDelete != null) {
            userManagementMapper.deleteById(userId);
        }
    }

    // 根据用户名删除用户
    public void deleteUserByUsername(String username) {
        UserManagement userToDelete = getUserByUsername(username);
        if (userToDelete != null) {
            userManagementMapper.delete(new QueryWrapper<UserManagement>().eq("username", username));
        }
    }


    // 检查用户名是否存在
    public boolean isUsernameExists(String username) {
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectCount(queryWrapper) > 0;
    }

}
