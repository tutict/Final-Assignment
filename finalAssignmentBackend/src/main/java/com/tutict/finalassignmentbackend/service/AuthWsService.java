package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.SysRole;
import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.entity.SysUserRole;
import com.tutict.finalassignmentbackend.enums.DataScope;
import com.tutict.finalassignmentbackend.enums.RoleType;
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
import java.util.Locale;
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
            RoleAggregation aggregation = aggregateRoles(user.getUserId());
            List<String> roles = aggregation.getRoleNames();
            if (roles.isEmpty()) {
                logger.severe(() -> String.format("No roles found for user: %s", loginRequest.getUsername()));
                recordFailedLogin(loginRequest.getUsername(), "NO_ROLES_ASSIGNED");
                throw new RuntimeException("No roles assigned to user.");
            }
            String rolesString = String.join(",", roles);
            String roleCodesCsv = String.join(",", aggregation.getRoleCodes());
            String roleTypesCsv = String.join(",", aggregation.getRoleTypes());
            String dataScopeCode = aggregation.getDataScope().getCode();

            boolean claimsSupported = StringUtils.hasText(roleCodesCsv)
                    && StringUtils.hasText(roleTypesCsv)
                    && tokenProvider.validateRoleClaims(roleCodesCsv, roleTypesCsv, dataScopeCode);

            String jwtToken;
            if (claimsSupported) {
                jwtToken = tokenProvider.createEnhancedToken(user.getUsername(), roleCodesCsv, roleTypesCsv, dataScopeCode);
            } else {
                logger.warning(() -> String.format("角色声明不完整, 回退使用基础 token, user=%s", user.getUsername()));
                jwtToken = tokenProvider.createToken(user.getUsername(), rolesString);
            }

            boolean systemRole = tokenProvider.hasSystemRole(jwtToken);
            boolean businessRole = tokenProvider.hasBusinessRole(jwtToken);
            boolean hasDepartmentScope = tokenProvider.hasDataScopePermission(jwtToken, DataScope.DEPARTMENT);

            logger.info(() -> String.format("User authenticated successfully (WS): %s with roles: %s",
                    loginRequest.getUsername(), rolesString));
            return Map.of(
                    "jwtToken", jwtToken,
                    "username", user.getUsername(),
                    "roles", roles,
                    "roleCodes", aggregation.getRoleCodes(),
                    "roleTypes", aggregation.getRoleTypes(),
                    "dataScope", dataScopeCode,
                    "systemRole", systemRole,
                    "businessRole", businessRole,
                    "departmentScope", hasDepartmentScope
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

    private RoleAggregation aggregateRoles(Long userId) {
        if (userId == null) {
            return RoleAggregation.empty();
        }
        try {
            List<SysUserRole> relations = sysUserRoleService.findByUserId(userId, 1, MAX_ROLE_PAGE_SIZE);
            if (relations == null || relations.isEmpty()) {
                return RoleAggregation.empty();
            }
            List<String> roleNames = new ArrayList<>();
            List<String> roleCodes = new ArrayList<>();
            List<String> roleTypes = new ArrayList<>();
            DataScope aggregatedScope = DataScope.SELF;

            for (SysUserRole relation : relations) {
                if (relation == null || relation.getRoleId() == null) {
                    continue;
                }
                SysRole role = sysRoleService.findById(relation.getRoleId());
                if (role == null) {
                    continue;
                }
                if (StringUtils.hasText(role.getRoleName())) {
                    roleNames.add(role.getRoleName());
                }
                String roleCode = resolveRoleCode(role);
                if (StringUtils.hasText(roleCode)) {
                    roleCodes.add(roleCode);
                }
                String roleType = resolveRoleType(role);
                if (StringUtils.hasText(roleType)) {
                    roleTypes.add(roleType);
                }
                DataScope requiredScope = resolveDataScope(role);
                aggregatedScope = widenScope(aggregatedScope, requiredScope);
            }

            return new RoleAggregation(
                    roleNames.stream().distinct().collect(Collectors.toList()),
                    roleCodes.stream().distinct().collect(Collectors.toList()),
                    roleTypes.stream().distinct().collect(Collectors.toList()),
                    aggregatedScope
            );
        } catch (Exception ex) {
            logger.log(Level.WARNING, "Failed to aggregate roles for userId=" + userId, ex);
            return RoleAggregation.empty();
        }
    }

    private String resolveRoleCode(SysRole role) {
        if (role == null) {
            return null;
        }
        String code = StringUtils.hasText(role.getRoleCode()) ? role.getRoleCode() : role.getRoleName();
        return StringUtils.hasText(code) ? code.trim().toUpperCase(Locale.ROOT) : null;
    }

    private String resolveRoleType(SysRole role) {
        if (role == null || !StringUtils.hasText(role.getRoleType())) {
            return RoleType.BUSINESS.getCode();
        }
        RoleType type = RoleType.fromCode(role.getRoleType());
        return type != null ? type.getCode() : RoleType.BUSINESS.getCode();
    }

    private DataScope resolveDataScope(SysRole role) {
        if (role == null) {
            return DataScope.SELF;
        }
        DataScope scope = DataScope.fromCode(role.getDataScope());
        return scope != null ? scope : DataScope.SELF;
    }

    private DataScope widenScope(DataScope current, DataScope candidate) {
        if (candidate == null) {
            return current;
        }
        if (current == null) {
            return candidate;
        }
        return scopeRank(candidate) > scopeRank(current) ? candidate : current;
    }

    private int scopeRank(DataScope scope) {
        if (scope == null) {
            return 0;
        }
        return switch (scope) {
            case CUSTOM -> 1;
            case SELF -> 2;
            case DEPARTMENT -> 3;
            case DEPARTMENT_AND_SUB -> 4;
            case ALL -> 5;
        };
    }

    private static class RoleAggregation {
        private final List<String> roleNames;
        private final List<String> roleCodes;
        private final List<String> roleTypes;
        private final DataScope dataScope;

        private RoleAggregation(List<String> roleNames, List<String> roleCodes, List<String> roleTypes, DataScope dataScope) {
            this.roleNames = roleNames;
            this.roleCodes = roleCodes;
            this.roleTypes = roleTypes;
            this.dataScope = dataScope == null ? DataScope.SELF : dataScope;
        }

        static RoleAggregation empty() {
            return new RoleAggregation(List.of(), List.of(), List.of(), DataScope.SELF);
        }

        List<String> getRoleNames() {
            return roleNames;
        }

        List<String> getRoleCodes() {
            return roleCodes;
        }

        List<String> getRoleTypes() {
            return roleTypes;
        }

        DataScope getDataScope() {
            return dataScope;
        }
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
