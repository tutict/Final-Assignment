package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

// 控制器类，处理与用户管理相关的请求
@RestController
@RequestMapping("/eventbus/users")
public class UserManagementController {

    public static final Logger logger = LoggerFactory.getLogger(UserManagementController.class);

    // 用户管理服务的依赖项
    private final UserManagementService userManagementService;

    // 构造函数，通过依赖注入初始化用户管理服务
    @Autowired
    public UserManagementController(UserManagementService userManagementService) {
        this.userManagementService = userManagementService;
    }

    // 创建新用户的POST请求处理方法
    // 如果用户名已存在，则返回冲突状态；否则创建用户并返回创建状态
    @PostMapping
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Void> createUser(@RequestBody UserManagement user) {
        logger.info("Attempting to create user: {}", user.getUsername());
        if (userManagementService.isUsernameExists(user.getUsername())) {
            logger.warn("Username already exists: {}", user.getUsername());
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        userManagementService.createUser(user);
        logger.info("User created successfully: {}", user.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据用户ID获取用户的GET请求处理方法
    // 如果找到用户，则返回该用户的信息；否则返回未找到状态
    @GetMapping("/{userId}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<UserManagement> getUserById(@PathVariable int userId) {
        logger.info("Fetching user by ID: {}", userId);
        UserManagement user = userManagementService.getUserById(userId);
        if (user != null) {
            logger.info("User found: {}", userId);
            return ResponseEntity.ok(user);
        } else {
            logger.warn("User not found: {}", userId);
            return ResponseEntity.notFound().build();
        }
    }

    // 根据用户名获取用户的GET请求处理方法
    // 如果找到用户，则返回该用户的信息；否则返回未找到状态
    @GetMapping("/username/{username}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<UserManagement> getUserByUsername(@PathVariable String username) {
        logger.info("Fetching user by username: {}", username);
        UserManagement user = userManagementService.getUserByUsername(username);
        if (user != null) {
            logger.info("User found: {}", username);
            return ResponseEntity.ok(user);
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有用户的GET请求处理方法
    // 返回用户列表
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UserManagement>> getAllUsers() {
        logger.info("Fetching all users");
        List<UserManagement> users = userManagementService.getAllUsers();
        logger.info("Total users found: {}", users.size());
        return ResponseEntity.ok(users);
    }

    // 根据用户类型获取用户的GET请求处理方法
    // 返回指定类型用户的列表
    @GetMapping("/type/{userType}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UserManagement>> getUsersByType(@PathVariable String userType) {
        logger.info("Fetching users by type: {}", userType);
        List<UserManagement> users = userManagementService.getUsersByType(userType);
        logger.info("Total users of type {}: {}", userType, users.size());
        return ResponseEntity.ok(users);
    }

    // 根据用户状态获取用户的GET请求处理方法
    // 返回指定状态用户的列表
    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UserManagement>> getUsersByStatus(@PathVariable String status) {
        logger.info("Fetching users by status: {}", status);
        List<UserManagement> users = userManagementService.getUsersByStatus(status);
        logger.info("Total users with status {}: {}", status, users.size());
        return ResponseEntity.ok(users);
    }

    // 更新指定用户ID的用户的PUT请求处理方法
    // 如果用户存在，则更新用户信息并返回OK状态；否则返回未找到状态
    @PutMapping("/{userId}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Void> updateUser(@PathVariable int userId, @RequestBody UserManagement updatedUser) {
        logger.info("Attempting to update user: {}", userId);
        UserManagement existingUser = userManagementService.getUserById(userId);
        if (existingUser != null) {
            updatedUser.setUserId(userId);
            userManagementService.updateUser(updatedUser);
            logger.info("User updated successfully: {}", userId);
            return ResponseEntity.ok().build();
        } else {
            logger.warn("User not found: {}", userId);
            return ResponseEntity.notFound().build();
        }
    }

    // 删除指定用户ID的用户的DELETE请求处理方法
    // 删除用户后返回无内容状态
    @DeleteMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUser(@PathVariable int userId) {
        logger.info("Attempting to delete user: {}", userId);
        try {
            userManagementService.deleteUser(userId);
            logger.info("User deleted successfully: {}", userId);
        } catch (Exception e) {
            logger.error("Error occurred while deleting user: {}", userId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
        return ResponseEntity.noContent().build();
    }

    // 删除指定用户名的用户的DELETE请求处理方法
    // 删除用户后返回无内容状态
    @DeleteMapping("/username/{username}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUserByUsername(@PathVariable String username) {
        logger.info("Attempting to delete user by username: {}", username);
        try {
            userManagementService.deleteUserByUsername(username);
            logger.info("User deleted successfully: {}", username);
        } catch (Exception e) {
            logger.error("Error occurred while deleting user by username: {}", username, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
        return ResponseEntity.noContent().build();
    }
}
