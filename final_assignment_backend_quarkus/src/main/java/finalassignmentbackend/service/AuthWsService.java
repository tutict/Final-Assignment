package finalassignmentbackend.service;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.entity.UserManagement;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

@ApplicationScoped
@RegisterForReflection
public class AuthWsService {

    private static final Logger logger = Logger.getLogger(AuthWsService.class.getName());

    @Inject
    TokenProvider tokenProvider;

    @Inject
    LoginLogService loginLogService;

    @Inject
    UserManagementService userManagementService;

    @Inject
    RoleManagementService roleManagementService;

    /*
     * WebSocket: 登录用户
     */
    @WsAction(service = "AuthWsService", action = "login")
    public Map<String, Object> login(LoginRequest loginRequest) {
        logger.info(String.format("[WS] Attempting to authenticate user: %s", loginRequest.getUsername()));

        UserManagement user = userManagementService.getUserByUsername(loginRequest.getUsername());
        if (user != null && authenticateUser(user, loginRequest.getPassword())) {
            // Fetch the user's role
            RoleManagement role = roleManagementService.getRoleByName(user.getUserType());
            if (role != null) {
                String roles = role.getRoleName();
                // create token
                String jwtToken = tokenProvider.createToken(user.getUsername(), roles);
                logger.info(String.format("User authenticated successfully (WS): %s", loginRequest.getUsername()));

                // 返回给WS
                return Map.of("jwtToken", jwtToken);
            } else {
                logger.severe(String.format("Role not found for user: %s", loginRequest.getUsername()));
                recordFailedLogin(loginRequest.getUsername());
                throw new RuntimeException("Role not found.");
            }
        } else {
            logger.severe(String.format("Authentication failed (WS) for user: %s", loginRequest.getUsername()));
            recordFailedLogin(loginRequest.getUsername());
            throw new RuntimeException("Invalid username or password.");
        }
    }

    /*
     * WebSocket: 注册用户
     */
    @Transactional
    @WsAction(service = "AuthWsService", action = "registerUser")
    public String registerUser(RegisterRequest registerRequest) {
        logger.info(String.format("[WS] Attempting to register user: %s", registerRequest.getUsername()));
        if (userManagementService.isUsernameExists(registerRequest.getUsername())) {
            logger.warning(String.format("Username already exists: %s", registerRequest.getUsername()));
            throw new RuntimeException("Username already exists.");
        }

        // 构造 user
        UserManagement newUser = new UserManagement();
        newUser.setUsername(registerRequest.getUsername());
        newUser.setPassword(registerRequest.getPassword());
        newUser.setUserType(registerRequest.getRole().equals("ADMIN") ? "ADMIN" : "USER");

        String idempotencyKey = registerRequest.getIdempotencyKey();
        userManagementService.checkAndInsertIdempotency(idempotencyKey, newUser, "create");

        logger.info(String.format("[WS] User registered successfully: %s", registerRequest.getUsername()));
        return "CREATED";
    }

    /*
     * WebSocket: 获取所有用户
     */
    @WsAction(service = "AuthWsService", action = "getAllUsers")
    @CacheResult(cacheName = "userCache")  // 可选
    public List<UserManagement> getAllUsers() {
        logger.info("[WS] Fetching all users");
        return userManagementService.getAllUsers();
    }

    private boolean authenticateUser(UserManagement user, String password) {
        // 简易验证
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
