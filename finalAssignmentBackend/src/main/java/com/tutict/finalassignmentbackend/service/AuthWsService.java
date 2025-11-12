package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.SysRole;
import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.entity.SysUserRole;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class AuthWsService {

    private static final Logger logger = Logger.getLogger(AuthWsService.class.getName());
    private static final int MAX_ROLE_PAGE_SIZE = 100;

    private final TokenProvider tokenProvider;
    private final AuditLoginLogService auditLoginLogService;
    private final SysUserService sysUserService;
    private final SysRoleService sysRoleService;
    private final SysUserRoleService sysUserRoleService;

    @Autowired
    public AuthWsService(TokenProvider tokenProvider,
                         AuditLoginLogService auditLoginLogService,
                         SysUserService sysUserService,
                         SysRoleService sysRoleService,
                         SysUserRoleService sysUserRoleService) {
        this.tokenProvider = tokenProvider;
        this.auditLoginLogService = auditLoginLogService;
        this.sysUserService = sysUserService;
        this.sysRoleService = sysRoleService;
        this.sysUserRoleService = sysUserRoleService;
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "login")
    public Map<String, Object> login(LoginRequest loginRequest) {
        validateLoginRequest(loginRequest);

        logger.info(() -> String.format("[WS] Attempting to authenticate user: %s", loginRequest.getUsername()));
        SysUser user = sysUserService.findByUsername(loginRequest.getUsername());

        if (user != null && authenticateUser(user, loginRequest.getPassword())) {
            List<String> roles = resolveRoleNames(user.getUserId());
            if (roles.isEmpty()) {
                logger.severe(() -> String.format("No roles found for user: %s", loginRequest.getUsername()));
                recordFailedLogin(loginRequest.getUsername(), "NO_ROLES_ASSIGNED");
                throw new RuntimeException("No roles assigned to user.");
            }
            String rolesString = String.join(",", roles);
            String jwtToken = tokenProvider.createToken(user.getUsername(), rolesString);
            logger.info(() -> String.format("User authenticated successfully (WS): %s with roles: %s",
                    loginRequest.getUsername(), rolesString));
            return Map.of(
                    "jwtToken", jwtToken,
                    "username", user.getUsername(),
                    "roles", roles
            );
        }

        logger.severe(() -> String.format("Authentication failed (WS) for user: %s", loginRequest.getUsername()));
        recordFailedLogin(loginRequest.getUsername(), "INVALID_CREDENTIALS");
        throw new RuntimeException("Invalid username or password.");
    }

    @Transactional
    @CacheEvict(cacheNames = {"AuthCache", "usernameExistsCache"}, allEntries = true)
    @WsAction(service = "AuthWsService", action = "registerUser")
    public String registerUser(RegisterRequest registerRequest) {
        validateRegisterRequest(registerRequest);
        logger.info(() -> String.format("尝试注册用户: %s", registerRequest.getUsername()));

        if (sysUserService.isUsernameExists(registerRequest.getUsername())) {
            logger.severe(() -> String.format("用户名已存在: %s", registerRequest.getUsername()));
            throw new RuntimeException("用户名已存在: " + registerRequest.getUsername());
        }

        String idempotencyKey = registerRequest.getIdempotencyKey();
        if (StringUtils.hasText(idempotencyKey)) {
            SysUser probe = new SysUser();
            probe.setUsername(registerRequest.getUsername());
            try {
                sysUserService.checkAndInsertIdempotency(idempotencyKey, probe, "create");
            } catch (RuntimeException e) {
                logger.log(Level.WARNING, "幂等性检查失败 {0}, 错误: {1}", new Object[]{idempotencyKey, e.getMessage()});
                throw new RuntimeException("注册失败: 重复请求", e);
            }
        }

        SysUser newUser = new SysUser();
        newUser.setUsername(registerRequest.getUsername());
        newUser.setPassword(registerRequest.getPassword()); // TODO: hash password
        newUser.setStatus("Active");
        newUser.setCreatedAt(LocalDateTime.now());
        newUser.setUpdatedAt(LocalDateTime.now());
        sysUserService.createSysUser(newUser);
        logger.info(() -> String.format("用户创建成功: %s", registerRequest.getUsername()));

        SysUser savedUser = sysUserService.findByUsername(registerRequest.getUsername());
        if (savedUser == null) {
            logger.warning(() -> String.format("无法获取新建用户: %s", registerRequest.getUsername()));
            throw new RuntimeException("用户创建失败，无法获取用户信息");
        }

        SysRole role = resolveOrCreateRole(registerRequest.getRole());
        assignRole(savedUser, role);

        logger.info(() -> String.format("用户注册成功: %s", registerRequest.getUsername()));
        return "CREATED";
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "getAllUsers")
    public List<SysUser> getAllUsers() {
        logger.info("[WS] Fetching all users");
        List<SysUser> users = sysUserService.getAllUsers();
        if (users.isEmpty()) {
            logger.warning("No users found in the system");
        }
        return users;
    }

    private void validateLoginRequest(LoginRequest loginRequest) {
        Objects.requireNonNull(loginRequest, "Login request must not be null");
        if (!StringUtils.hasText(loginRequest.getUsername())) {
            logger.severe("Authentication failed: username is null or empty");
            throw new RuntimeException("Invalid username");
        }
        if (!StringUtils.hasText(loginRequest.getPassword())) {
            logger.severe("Authentication failed: password is null or empty");
            throw new RuntimeException("Invalid password");
        }
    }

    private void validateRegisterRequest(RegisterRequest registerRequest) {
        Objects.requireNonNull(registerRequest, "Register request must not be null");
        if (!StringUtils.hasText(registerRequest.getUsername())) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        if (!StringUtils.hasText(registerRequest.getPassword())) {
            throw new IllegalArgumentException("密码不能为空");
        }
    }

    private boolean authenticateUser(SysUser user, String password) {
        return Objects.equals(user.getPassword(), password);
    }

    private List<String> resolveRoleNames(Long userId) {
        if (userId == null) {
            return List.of();
        }
        try {
            List<SysUserRole> relations = sysUserRoleService.findByUserId(userId, 1, MAX_ROLE_PAGE_SIZE);
            if (relations == null || relations.isEmpty()) {
                return List.of();
            }
            List<String> names = new ArrayList<>();
            for (SysUserRole relation : relations) {
                if (relation == null || relation.getRoleId() == null) {
                    continue;
                }
                SysRole role = sysRoleService.findById(relation.getRoleId());
                if (role != null && StringUtils.hasText(role.getRoleName())) {
                    names.add(role.getRoleName());
                }
            }
            return names.stream().distinct().collect(Collectors.toList());
        } catch (Exception ex) {
            logger.log(Level.WARNING, "Failed to resolve roles for userId=" + userId, ex);
            return List.of();
        }
    }

    private SysRole resolveOrCreateRole(String requestedRole) {
        String roleCode = StringUtils.hasText(requestedRole) ? requestedRole : "USER";
        SysRole role = sysRoleService.findByRoleCode(roleCode);
        if (role != null) {
            return role;
        }
        logger.info(() -> String.format("Role %s not found, creating automatically", roleCode));
        SysRole newRole = new SysRole();
        newRole.setRoleCode(roleCode);
        newRole.setRoleName(roleCode);
        newRole.setRoleDescription("AUTO_CREATED_BY_AUTH_WS");
        newRole.setRoleType("Custom");
        newRole.setStatus("Active");
        newRole.setCreatedAt(LocalDateTime.now());
        return sysRoleService.createSysRole(newRole);
    }

    private void assignRole(SysUser user, SysRole role) {
        SysUserRole relation = new SysUserRole();
        relation.setUserId(user.getUserId());
        relation.setRoleId(role.getRoleId());
        relation.setCreatedAt(LocalDateTime.now());
        relation.setCreatedBy("AuthWsService");
        sysUserRoleService.createRelation(relation);
    }

    private void recordFailedLogin(String username, String reason) {
        AuditLoginLog loginLog = new AuditLoginLog();
        loginLog.setUsername(username);
        loginLog.setLoginTime(LocalDateTime.now());
        loginLog.setLoginResult("FAILED");
        loginLog.setFailureReason(reason);
        auditLoginLogService.createAuditLoginLog(loginLog);
    }

    @Data
    public static class LoginRequest {
        private String username;
        private String password;
    }

    @Data
    public static class RegisterRequest {
        private String username;
        private String password;
        private String role;
        private String idempotencyKey;
    }
}
