package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
@RequestMapping("/api/users")
public class UserManagementController {

    private static final Logger logger = LoggerFactory.getLogger(UserManagementController.class);

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final UserManagementService userManagementService;

    public UserManagementController(UserManagementService userManagementService) {
        this.userManagementService = userManagementService;
    }

    @PostMapping
    @Async
    public CompletableFuture<ResponseEntity<Void>> createUser(@RequestBody UserManagement user, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Attempting to create user: {}", user.getUsername());
            if (userManagementService.isUsernameExists(user.getUsername())) {
                logger.warn("Username already exists: {}", user.getUsername());
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            userManagementService.checkAndInsertIdempotency(idempotencyKey, user, "create");
            logger.info("User created successfully: {}", user.getUsername());
            return ResponseEntity.status(HttpStatus.CREATED).build();
        }, virtualThreadExecutor);
    }

    @GetMapping("/me")
    @Async
    public CompletableFuture<ResponseEntity<UserManagement>> getCurrentUser(@RequestParam String username) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching current user by username: {}", username);
            UserManagement existingUser = userManagementService.getUserByUsername(username);
            if (existingUser != null) {
                logger.info("User found: {}", username);
                return ResponseEntity.ok(existingUser);
            } else {
                logger.warn("User not found: {}", username);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    @PutMapping("/me")
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<Void>> updateCurrentUser(@RequestBody UserManagement updatedUser, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            String username = updatedUser.getUsername();
            logger.info("Attempting to update current user: {}", username);
            UserManagement existingUser = userManagementService.getUserByUsername(username);
            if (existingUser != null) {
                updatedUser.setUserId(existingUser.getUserId());
                userManagementService.checkAndInsertIdempotency(idempotencyKey, updatedUser, "update");
                logger.info("User updated successfully: {}", username);
                return ResponseEntity.ok().build();
            } else {
                logger.warn("User not found: {}", username);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    @GetMapping
    @Async
    public CompletableFuture<ResponseEntity<List<UserManagement>>> getAllUsers() {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching all users");
            List<UserManagement> users = userManagementService.getAllUsers();
            logger.info("Total users found: {}", users.size());
            return ResponseEntity.ok(users);
        }, virtualThreadExecutor);
    }

    @GetMapping("/{userId}")
    @Async
    public CompletableFuture<ResponseEntity<UserManagement>> getUserById(@PathVariable int userId) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching user by ID: {}", userId);
            UserManagement user = userManagementService.getUserById(userId);
            if (user != null) {
                logger.info("User found: {}", userId);
                return ResponseEntity.ok(user);
            } else {
                logger.warn("User not found: {}", userId);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    @GetMapping("/username/{username}")
    @Async
    public CompletableFuture<ResponseEntity<UserManagement>> getUserByUsername(@PathVariable String username) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching user by username: {}", username);
            UserManagement user = userManagementService.getUserByUsername(username);
            if (user != null) {
                logger.info("User found: {}", username);
                return ResponseEntity.ok(user);
            } else {
                logger.warn("User not found: {}", username);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    @GetMapping("/role/{roleName}")
    @Async
    public CompletableFuture<ResponseEntity<List<UserManagement>>> getUsersByRole(@PathVariable String roleName) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching users by role: {}", roleName);
            List<UserManagement> users = userManagementService.getUsersByRole(roleName);
            logger.info("Total users of role {}: {}", roleName, users.size());
            return ResponseEntity.ok(users);
        }, virtualThreadExecutor);
    }

    @GetMapping("/status/{status}")
    @Async
    public CompletableFuture<ResponseEntity<List<UserManagement>>> getUsersByStatus(@PathVariable String status) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Fetching users by status: {}", status);
            List<UserManagement> users = userManagementService.getUsersByStatus(status);
            logger.info("Total users with status {}: {}", status, users.size());
            return ResponseEntity.ok(users);
        }, virtualThreadExecutor);
    }

    @PutMapping("/{userId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> updateUser(@PathVariable int userId, @RequestBody UserManagement updatedUser, @RequestParam String idempotencyKey) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Attempting to update user: {}", userId);
            UserManagement existingUser = userManagementService.getUserById(userId);
            if (existingUser != null) {
                updatedUser.setUserId(userId);
                userManagementService.checkAndInsertIdempotency(idempotencyKey, updatedUser, "update");
                logger.info("User updated successfully: {}", userId);
                return ResponseEntity.ok().build();
            } else {
                logger.warn("User not found: {}", userId);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }, virtualThreadExecutor);
    }

    @DeleteMapping("/{userId}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteUser(@PathVariable int userId) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Attempting to delete user: {}", userId);
            try {
                UserManagement userToDelete = userManagementService.getUserById(userId);
                if (userToDelete != null) {
                    userManagementService.deleteUser(userId);
                    logger.info("User deleted successfully: {}", userId);
                } else {
                    logger.warn("User not found: {}", userId);
                    return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
                }
            } catch (Exception e) {
                logger.error("An error occurred while processing request for user {}", userId, e);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
            }
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }

    @DeleteMapping("/username/{username}")
    @Async
    public CompletableFuture<ResponseEntity<Void>> deleteUserByUsername(@PathVariable String username) {
        return CompletableFuture.supplyAsync(() -> {
            logger.info("Attempting to delete user by username: {}", username);
            try {
                UserManagement userToDelete = userManagementService.getUserByUsername(username);
                if (userToDelete != null) {
                    userManagementService.deleteUserByUsername(username);
                    logger.info("User deleted successfully: {}", username);
                } else {
                    logger.warn("User not found: {}", username);
                    return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
                }
            } catch (Exception e) {
                logger.error("An error occurred while processing request for user {}", username, e);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
            }
            return ResponseEntity.noContent().build();
        }, virtualThreadExecutor);
    }
}