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

    @PostMapping("/login")
    @PermitAll
    @Async
    public CompletableFuture<ResponseEntity<Map<String, Object>>> login(@RequestBody AuthWsService.LoginRequest loginRequest) {
        if (loginRequest == null || loginRequest.getUsername() == null || loginRequest.getPassword() == null) {
            logger.log(Level.SEVERE, "Login request invalid: null or missing username/password");
            return CompletableFuture.completedFuture(
                    ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", "Username and password are required")));
        }
        return CompletableFuture.supplyAsync(() -> {
            try {
                Map<String, Object> result = authWsService.login(loginRequest);
                if (result.containsKey("jwtToken")) {
                    logger.log(Level.INFO, "Login succeeded for username: {0}", loginRequest.getUsername());
                    return ResponseEntity.ok(result);
                } else {
                    logger.log(Level.WARNING, "Login failed for username: {0}", loginRequest.getUsername());
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
                }
            } catch (Exception e) {
                logger.log(Level.SEVERE, "Login failed for username: {0}, error: {1}", new Object[]{loginRequest.getUsername(), e.getMessage()});
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", e.getMessage()));
            }
        }, virtualThreadExecutor);
    }

    @PostMapping("/register")
    @PermitAll
    @Async
    @Transactional
    public CompletableFuture<ResponseEntity<Map<String, String>>> registerUser(@RequestBody AuthWsService.RegisterRequest registerRequest) {
        logger.log(Level.INFO, "Received register request for username: {0}", registerRequest.getUsername());
        return CompletableFuture.supplyAsync(() -> {
                    try {
                        String res = authWsService.registerUser(registerRequest);
                        logger.log(Level.INFO, "Register succeeded for username: {0}", registerRequest.getUsername());
                        return ResponseEntity.status(HttpStatus.CREATED)
                                .header("Content-Type", "application/json")
                                .body(Map.of("status", res));
                    } catch (Exception e) {
                        logger.log(Level.SEVERE, "Register failed for username: {0}, error: {1}", new Object[]{registerRequest.getUsername(), e.getMessage()});
                        return ResponseEntity.status(HttpStatus.CONFLICT)
                                .header("Content-Type", "application/json")
                                .body(Map.of("error", e.getMessage()));
                    }
                }, virtualThreadExecutor)
                .exceptionally(throwable -> {
                    logger.log(Level.SEVERE, "Unexpected error in registerUser for username: {0}, error: {1}",
                            new Object[]{registerRequest.getUsername(), throwable.getMessage()});
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .header("Content-Type", "application/json")
                            .body(Map.of("error", "Internal server error"));
                });
    }

    @GetMapping("/users")
    @RolesAllowed("ADMIN")
    public ResponseEntity<List<UserManagement>> getAllUsers() {
        try {
            List<UserManagement> users = authWsService.getAllUsers();
            logger.log(Level.INFO, "Fetched {0} users successfully", users.size());
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "GetAllUsers failed: {0}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(List.of());
        }
    }
}