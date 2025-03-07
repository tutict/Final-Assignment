package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserManagementController {

    private static final Logger logger = LoggerFactory.getLogger(UserManagementController.class);
    private final UserManagementService userManagementService;

    @Autowired
    public UserManagementController(UserManagementService userManagementService) {
        this.userManagementService = userManagementService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createUser(@RequestBody UserManagement user, @RequestParam String idempotencyKey) {
        logger.info("Attempting to create user: {}", user.getUsername());
        if (userManagementService.isUsernameExists(user.getUsername())) {
            logger.warn("Username already exists: {}", user.getUsername());
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
        userManagementService.checkAndInsertIdempotency(idempotencyKey, user, "create");
        logger.info("User created successfully: {}", user.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<UserManagement> getCurrentUser(Principal principal) {
        logger.info("Entering getCurrentUser method");
        if (principal == null) {
            logger.warn("Principal is null, no authenticated user");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        String username = principal.getName();
        logger.info("Fetching current user from JWT: {}", username);
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            logger.info("User found: {}", username);
            return ResponseEntity.ok(existingUser);
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @PutMapping("/me")
    @Transactional
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<Void> updateCurrentUser(@RequestBody UserManagement updatedUser, @RequestParam String idempotencyKey, Principal principal) {
        String username = principal.getName();
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
    }

    // New endpoint to update password
    @PutMapping("/me/password")
    @Transactional
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<Void> updatePassword( @RequestBody String password, @RequestParam String idempotencyKey, Principal principal) {
        if (principal == null) {
            logger.warn("Principal is null, no authenticated user");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        String username = principal.getName();
        logger.info("Attempting to update password for user: {}", username);
        UserManagement existingUser = userManagementService.getUserByUsername(username);
        if (existingUser != null) {
            String cleanedPassword = password.replaceAll("^\"|\"$", "");
            existingUser.setPassword(cleanedPassword);
            userManagementService.checkAndInsertIdempotency(idempotencyKey, existingUser, "update");
            logger.info("Password updated successfully for user: {}", username);
            return ResponseEntity.ok().build();
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<UserManagement>> getAllUsers() {
        logger.info("Fetching all users");
        List<UserManagement> users = userManagementService.getAllUsers();
        logger.info("Total users found: {}", users.size());
        return ResponseEntity.ok(users);
    }

    @GetMapping("/{userId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<UserManagement> getUserById(@PathVariable int userId) {
        logger.info("Fetching user by ID: {}", userId);
        UserManagement user = userManagementService.getUserById(userId);
        if (user != null) {
            logger.info("User found: {}", userId);
            return ResponseEntity.ok(user);
        } else {
            logger.warn("User not found: {}", userId);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/username/{username}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<UserManagement> getUserByUsername(@PathVariable String username) {
        logger.info("Fetching user by username: {}", username);
        UserManagement user = userManagementService.getUserByUsername(username);
        if (user != null) {
            logger.info("User found: {}", username);
            return ResponseEntity.ok(user);
        } else {
            logger.warn("User not found: {}", username);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @GetMapping("/role/{roleName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<UserManagement>> getUsersByRole(@PathVariable String roleName) {
        logger.info("Fetching users by role: {}", roleName);
        List<UserManagement> users = userManagementService.getUsersByRole(roleName);
        logger.info("Total users of role {}: {}", roleName, users.size());
        return ResponseEntity.ok(users);
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<UserManagement>> getUsersByStatus(@PathVariable String status) {
        logger.info("Fetching users by status: {}", status);
        List<UserManagement> users = userManagementService.getUsersByStatus(status);
        logger.info("Total users with status {}: {}", status, users.size());
        return ResponseEntity.ok(users);
    }

    @PutMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> updateUser(@PathVariable int userId, @RequestBody UserManagement updatedUser, @RequestParam String idempotencyKey) {
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
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (Exception e) {
            logger.error("An error occurred while processing request for user {}", userId, e);
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
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (Exception e) {
            logger.error("An error occurred while processing request for user {}", username, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
        return ResponseEntity.noContent().build();
    }
}