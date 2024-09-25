package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

// 控制器类，处理与用户管理相关的HTTP请求
@RestController
@RequestMapping("/eventbus/users")
public class UserManagementController {

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
    public ResponseEntity<Void> createUser(@RequestBody UserManagement user) {
        if (userManagementService.isUsernameExists(user.getUsername())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        userManagementService.createUser(user);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据用户ID获取用户的GET请求处理方法
    // 如果找到用户，则返回该用户的信息；否则返回未找到状态
    @GetMapping("/{userId}")
    public ResponseEntity<UserManagement> getUserById(@PathVariable int userId) {
        UserManagement user = userManagementService.getUserById(userId);
        if (user != null) {
            return ResponseEntity.ok(user);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 根据用户名获取用户的GET请求处理方法
    // 如果找到用户，则返回该用户的信息；否则返回未找到状态
    @GetMapping("/username/{username}")
    public ResponseEntity<UserManagement> getUserByUsername(@PathVariable String username) {
        UserManagement user = userManagementService.getUserByUsername(username);
        if (user != null) {
            return ResponseEntity.ok(user);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有用户的GET请求处理方法
    // 返回用户列表
    @GetMapping
    public ResponseEntity<List<UserManagement>> getAllUsers() {
        List<UserManagement> users = userManagementService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    // 根据用户类型获取用户的GET请求处理方法
    // 返回指定类型用户的列表
    @GetMapping("/type/{userType}")
    public ResponseEntity<List<UserManagement>> getUsersByType(@PathVariable String userType) {
        List<UserManagement> users = userManagementService.getUsersByType(userType);
        return ResponseEntity.ok(users);
    }

    // 根据用户状态获取用户的GET请求处理方法
    // 返回指定状态用户的列表
    @GetMapping("/status/{status}")
    public ResponseEntity<List<UserManagement>> getUsersByStatus(@PathVariable String status) {
        List<UserManagement> users = userManagementService.getUsersByStatus(status);
        return ResponseEntity.ok(users);
    }

    // 更新指定用户ID的用户的PUT请求处理方法
    // 如果用户存在，则更新用户信息并返回OK状态；否则返回未找到状态
    @PutMapping("/{userId}")
    public ResponseEntity<Void> updateUser(@PathVariable int userId, @RequestBody UserManagement updatedUser) {
        UserManagement existingUser = userManagementService.getUserById(userId);
        if (existingUser != null) {
            updatedUser.setUserId(userId);
            userManagementService.updateUser(updatedUser);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除指定用户ID的用户的DELETE请求处理方法
    // 删除用户后返回无内容状态
    @DeleteMapping("/{userId}")
    public ResponseEntity<Void> deleteUser(@PathVariable int userId) {
        userManagementService.deleteUser(userId);
        return ResponseEntity.noContent().build();
    }

    // 删除指定用户名的用户的DELETE请求处理方法
    // 删除用户后返回无内容状态
    @DeleteMapping("/username/{username}")
    public ResponseEntity<Void> deleteUserByUsername(@PathVariable String username) {
        userManagementService.deleteUserByUsername(username);
        return ResponseEntity.noContent().build();
    }
}
