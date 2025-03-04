package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import lombok.Getter;
import lombok.Setter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class AuthWsService {

    private static final Logger logger = Logger.getLogger(AuthWsService.class.getName());

    private final TokenProvider tokenProvider;
    private final LoginLogService loginLogService;
    private final UserManagementService userManagementService;
    private final RoleManagementService roleManagementService;
    private final RoleManagementService userRoleService;

    @Autowired
    public AuthWsService(TokenProvider tokenProvider,
                         LoginLogService loginLogService,
                         UserManagementService userManagementService,
                         RoleManagementService roleManagementService,
                         RoleManagementService userRoleService) {
        this.tokenProvider = tokenProvider;
        this.loginLogService = loginLogService;
        this.userManagementService = userManagementService;
        this.roleManagementService = roleManagementService;
        this.userRoleService = userRoleService;
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "login")
    public Map<String, Object> login(LoginRequest loginRequest) {
        if (loginRequest.getUsername() == null || loginRequest.getUsername().isEmpty()) {
            logger.severe("Authentication failed: username is null or empty");
            throw new RuntimeException("Invalid username");
        }
        if (loginRequest.getPassword() == null || loginRequest.getPassword().isEmpty()) {
            logger.severe("Authentication failed: password is null or empty");
            throw new RuntimeException("Invalid password");
        }

        logger.info(String.format("[WS] Attempting to authenticate user: %s", loginRequest.getUsername()));
        UserManagement user = userManagementService.getUserByUsername(loginRequest.getUsername());

        if (user != null && authenticateUser(user, loginRequest.getPassword())) {
            List<RoleManagement> roles = roleManagementService.getRolesByUserId(user.getUserId());
            if (roles != null && !roles.isEmpty()) {
                String rolesString = roles.stream()
                        .map(RoleManagement::getRoleName)
                        .collect(Collectors.joining(","));
                String jwtToken = tokenProvider.createToken(user.getUsername(), rolesString);
                logger.info(String.format("User authenticated successfully (WS): %s with roles: %s", loginRequest.getUsername(), rolesString));
                return Map.of("jwtToken", jwtToken);
            } else {
                logger.severe(String.format("No roles found for user: %s", loginRequest.getUsername()));
                recordFailedLogin(loginRequest.getUsername());
                throw new RuntimeException("No roles assigned to user.");
            }
        } else {
            logger.severe(String.format("Authentication failed (WS) for user: %s", loginRequest.getUsername()));
            recordFailedLogin(loginRequest.getUsername());
            throw new RuntimeException("Invalid username or password.");
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "registerUser")
    public String registerUser(RegisterRequest registerRequest) {
        logger.info(String.format("[WS] Attempting to register user: %s", registerRequest.getUsername()));
        if (userManagementService.isUsernameExists(registerRequest.getUsername())) {
            logger.warning(String.format("Username already exists: %s", registerRequest.getUsername()));
            throw new RuntimeException("Username already exists.");
        }

        UserManagement newUser = new UserManagement();
        newUser.setUsername(registerRequest.getUsername());
        newUser.setPassword(registerRequest.getPassword());
        newUser.setCreatedTime(LocalDateTime.now());

        userManagementService.createUser(newUser);

        String roleName = registerRequest.getRole();
        RoleManagement role = roleManagementService.getRoleByName(roleName);
        if (role == null) {
            role = new RoleManagement();
            role.setRoleName(roleName);
            role.setRoleDescription(roleName.equals("ADMIN") ? "管理员角色" : "普通用户角色");
            role.setCreatedTime(LocalDateTime.now());
            roleManagementService.createRole(role);
        }

        QueryWrapper<UserManagement> userQuery = new QueryWrapper<>();
        userQuery.eq("username", newUser.getUsername());
        UserManagement savedUser = userManagementService.getUserByUsername(newUser.getUsername());
        if (savedUser != null) {
            userRoleService.assignRole(savedUser.getUserId(), role.getRoleId());
        } else {
            logger.severe("Failed to retrieve newly created user: " + newUser.getUsername());
            throw new RuntimeException("User creation failed.");
        }

        logger.info(String.format("[WS] User registered successfully: %s", registerRequest.getUsername()));
        return "CREATED";
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "getAllUsers")
    public List<UserManagement> getAllUsers() {
        logger.info("[WS] Fetching all users");
        List<UserManagement> users = userManagementService.getAllUsers();
        if (users.isEmpty()) {
            logger.warning("No users found in the system");
        }
        return users;
    }

    private boolean authenticateUser(UserManagement user, String password) {
        return user.getPassword().equals(password);
    }

    private void recordFailedLogin(String username) {
        LoginLog loginLog = new LoginLog();
        loginLog.setUsername(username);
        loginLog.setLoginTime(LocalDateTime.now());
        loginLog.setLoginResult("FAILED");
        loginLogService.createLoginLog(loginLog);
    }

    @Getter
    @Setter
    public static class LoginRequest {
        private String username;
        private String password;
    }

    @Getter
    @Setter
    public static class RegisterRequest {
        private String username;
        private String password;
        private String role;
        private String idempotencyKey;
    }
}