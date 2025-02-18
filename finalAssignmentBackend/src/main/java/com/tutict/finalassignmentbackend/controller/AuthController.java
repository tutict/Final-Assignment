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
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger logger = Logger.getLogger(AuthController.class.getName());

    // Creating virtual thread pool
    private static final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    private final AuthWsService authWsService;

    public AuthController(AuthWsService authWsService) {
        this.authWsService = authWsService;
    }

    // Login method
    @PostMapping("/login")
    @PermitAll
    @Async
    public CompletableFuture<ResponseEntity<Map<String, Object>>> login(@RequestBody AuthWsService.LoginRequest loginRequest) {
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

    // Register method
    @PostMapping("/register")
    @PermitAll
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<Map<String, String>>> registerUser(@RequestBody AuthWsService.RegisterRequest registerRequest) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                String res = authWsService.registerUser(registerRequest);
                return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("status", res));
            } catch (Exception e) {
                logger.warning("Register failed: " + e.getMessage());
                return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("error", e.getMessage()));
            }
        }, virtualThreadExecutor);
    }

    // Get all users (Admin only)
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
