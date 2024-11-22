package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
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

    private final UserManagementService userManagementService;

    @Autowired
    public UserManagementController(UserManagementService userManagementService) {
        this.userManagementService = userManagementService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
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

    @GetMapping("/me")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<UserManagement> getCurrentUser(Authentication authentication) {
        String username = authentication.getName();
        logger.info("Fetching current user by username: {}", username);
        UserManagement user = userManagementService.getUserByUsername(username);
        if (user != null) {
            logger.info("User found: {}", username);
            return ResponseEntity.ok(user);
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/me")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<UserManagement> updateCurrentUser(Authentication authentication, @RequestBody UserManagement updatedUser) {
        String username = authentication.getName();
        logger.info("Attempting to update current user: {}", username);
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            updatedUser.setUserId(existingUser.getUserId());
            UserManagement updatedUserResult = userManagementService.updateUser(updatedUser);
            logger.info("User updated successfully: {}", username);
            return ResponseEntity.ok(updatedUserResult);
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UserManagement>> getAllUsers() {
        logger.info("Fetching all users");
        List<UserManagement> users = userManagementService.getAllUsers();
        logger.info("Total users found: {}", users.size());
        return ResponseEntity.ok(users);
    }

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

    @GetMapping("/type/{userType}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UserManagement>> getUsersByType(@PathVariable String userType) {
        logger.info("Fetching users by type: {}", userType);
        List<UserManagement> users = userManagementService.getUsersByType(userType);
        logger.info("Total users of type {}: {}", userType, users.size());
        return ResponseEntity.ok(users);
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UserManagement>> getUsersByStatus(@PathVariable String status) {
        logger.info("Fetching users by status: {}", status);
        List<UserManagement> users = userManagementService.getUsersByStatus(status);
        logger.info("Total users with status {}: {}", status, users.size());
        return ResponseEntity.ok(users);
    }

    @PutMapping("/{userId}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<UserManagement> updateUser(@PathVariable int userId, @RequestBody UserManagement updatedUser) {
        logger.info("Attempting to update user: {}", userId);
        UserManagement existingUser = userManagementService.getUserById(userId);
        if (existingUser != null) {
            updatedUser.setUserId(userId);
            UserManagement updatedUserResult = userManagementService.updateUser(updatedUser);
            logger.info("User updated successfully: {}", userId);
            return ResponseEntity.ok(updatedUserResult);
        } else {
            logger.warn("User not found: {}", userId);
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUser(@PathVariable int userId) {
        logger.info("Attempting to delete user: {}", userId);
        try {
            UserManagement userToDelete = userManagementService.getUserById(userId);
            if (userToDelete != null) {
                userManagementService.deleteUser(userId);
                logger.info("User deleted successfully: {}", userId);
            } else {
                logger.warn("User not found: {}", userId);
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            logger.error("Error occurred while deleting user: {}", userId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/username/{username}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteUserByUsername(@PathVariable String username) {
        logger.info("Attempting to delete user by username: {}", username);
        try {
            UserManagement userToDelete = userManagementService.getUserByUsername(username);
            if (userToDelete != null) {
                userManagementService.deleteUserByUsername(username);
                logger.info("User deleted successfully: {}", username);
            } else {
                logger.warn("User not found: {}", username);
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            logger.error("Error occurred while deleting user by username: {}", username, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
        return ResponseEntity.noContent().build();
    }
}
