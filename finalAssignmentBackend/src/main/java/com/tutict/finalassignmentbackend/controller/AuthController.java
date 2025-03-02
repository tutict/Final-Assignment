package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.AuthWsService;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger logger = Logger.getLogger(AuthController.class.getName());

    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final AuthWsService authWsService;

    public AuthController(AuthWsService authWsService) {
        this.authWsService = authWsService;
    }

    // Login method (无需认证)
    @PostMapping("/login")
    @PermitAll
    @Async
    public CompletableFuture<ResponseEntity<Map<String, Object>>> login(@RequestBody AuthWsService.LoginRequest loginRequest) {
        if (loginRequest == null || loginRequest.getUsername() == null || loginRequest.getPassword() == null) {
            return CompletableFuture.completedFuture(
                    ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", "Username and password are required")));
        }
        return CompletableFuture.supplyAsync(() -> {
            try {
                Map<String, Object> result = authWsService.login(loginRequest);
                if (result.containsKey("jwtToken")) {
                    return ResponseEntity.ok(result);
                } else {
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
                }
            } catch (Exception e) {
                logger.warning("Login failed: " + e.getMessage());
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", e.getMessage()));
            }
        }, virtualThreadExecutor);
    }

    // Register method (无需认证)
    @PostMapping("/register")
    @PermitAll
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<Map<String, String>>> registerUser(@RequestBody AuthWsService.RegisterRequest registerRequest) {
        logger.log(Level.WARNING, "Received register request for username: {}", registerRequest.getUsername());
        return CompletableFuture.supplyAsync(() -> {
                    try {
                        String res = authWsService.registerUser(registerRequest);
                        logger.log(Level.WARNING, "Register succeeded for username: {}", registerRequest.getUsername());
                        return ResponseEntity.status(HttpStatus.CREATED)
                                .header("Content-Type", "application/json")
                                .body(Map.of("status", res));
                    } catch (Exception e) {
                        logger.log(Level.WARNING, "Register failed for username: {} ", registerRequest.getUsername());
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .header("Content-Type", "application/json")
                                .body(Map.of("error", e.getMessage()));
                    }
                }, virtualThreadExecutor)
                .exceptionally(throwable -> {
                    logger.log(Level.WARNING, "Unexpected error in registerUser for username: {}", registerRequest.getUsername());
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .header("Content-Type", "application/json")
                            .body(Map.of("error", "Internal server error"));
                });
    }

    // Get all users (仅 ADMIN)
    @GetMapping("/users")
    @RolesAllowed("ADMIN")
    @Async
    public CompletableFuture<ResponseEntity<? extends List<?>>> getAllUsers() {
        return CompletableFuture.supplyAsync(() -> {
            try {
                List<UserManagement> users = authWsService.getAllUsers();
                return ResponseEntity.ok(users);
            } catch (Exception e) {
                logger.warning("GetAllUsers failed: " + e.getMessage());
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(List.of(Map.of("error", e.getMessage())));
            }
        }, virtualThreadExecutor);
    }
}