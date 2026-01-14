package com.tutict.finalassignmentcloud.auth.service;

import com.tutict.finalassignmentcloud.auth.client.AuditLogClient;
import com.tutict.finalassignmentcloud.auth.client.RoleClient;
import com.tutict.finalassignmentcloud.auth.client.UserClient;
import com.tutict.finalassignmentcloud.auth.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.AuditLoginLog;
import com.tutict.finalassignmentcloud.entity.SysRole;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.entity.SysUserRole;
import com.tutict.finalassignmentcloud.enums.DataScope;
import com.tutict.finalassignmentcloud.enums.RoleType;
import feign.FeignException;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
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
    private final AuditLogClient auditLogClient;
    private final UserClient userClient;
    private final RoleClient roleClient;

    @Autowired
    public AuthWsService(TokenProvider tokenProvider,
                         AuditLogClient auditLogClient,
                         UserClient userClient,
                         RoleClient roleClient) {
        this.tokenProvider = tokenProvider;
        this.auditLogClient = auditLogClient;
        this.userClient = userClient;
        this.roleClient = roleClient;
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "login")
    public Map<String, Object> login(LoginRequest loginRequest) {
        validateLoginRequest(loginRequest);

        logger.info(() -> String.format("[WS] Attempting to authenticate user: %s", loginRequest.getUsername()));
        SysUser user = safeGetByUsername(loginRequest.getUsername());

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
                logger.warning(() -> String.format("Role claims are incomplete; falling back to base token for user=%s",
                        user.getUsername()));
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
        logger.info(() -> String.format("Attempting to register user: %s", registerRequest.getUsername()));

        if (safeGetByUsername(registerRequest.getUsername()) != null) {
            logger.severe(() -> String.format("Username already exists: %s", registerRequest.getUsername()));
            throw new RuntimeException("Username already exists: " + registerRequest.getUsername());
        }

        String idempotencyKey = registerRequest.getIdempotencyKey();

        SysUser newUser = new SysUser();
        newUser.setUsername(registerRequest.getUsername());
        newUser.setPassword(registerRequest.getPassword()); // TODO: hash password
        newUser.setStatus("Active");
        newUser.setCreatedAt(LocalDateTime.now());
        newUser.setUpdatedAt(LocalDateTime.now());
        SysUser savedUser = userClient.createUser(newUser, idempotencyKey);
        logger.info(() -> String.format("User created successfully: %s", registerRequest.getUsername()));

        if (savedUser == null || savedUser.getUserId() == null) {
            savedUser = safeGetByUsername(registerRequest.getUsername());
        }
        if (savedUser == null) {
            logger.warning(() -> String.format("Unable to load newly created user: %s", registerRequest.getUsername()));
            throw new RuntimeException("User creation failed; unable to load user info");
        }

        SysRole role = resolveOrCreateRole(registerRequest.getRole());
        assignRole(savedUser, role);

        logger.info(() -> String.format("User registered successfully: %s", registerRequest.getUsername()));
        return "CREATED";
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "getAllUsers")
    public List<SysUser> getAllUsers() {
        logger.info("[WS] Fetching all users");
        List<SysUser> users = userClient.getAllUsers();
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
            throw new IllegalArgumentException("Username must not be blank");
        }
        if (!StringUtils.hasText(registerRequest.getPassword())) {
            throw new IllegalArgumentException("Password must not be blank");
        }
    }

    private boolean authenticateUser(SysUser user, String password) {
        return Objects.equals(user.getPassword(), password);
    }

    private SysRole resolveOrCreateRole(String requestedRole) {
        String roleCode = StringUtils.hasText(requestedRole) ? requestedRole : "USER";
        SysRole role = safeGetRoleByCode(roleCode);
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
        return roleClient.create(newRole, null);
    }

    private void assignRole(SysUser user, SysRole role) {
        SysUserRole relation = new SysUserRole();
        relation.setUserId(user.getUserId());
        relation.setRoleId(role.getRoleId());
        relation.setCreatedAt(LocalDateTime.now());
        relation.setCreatedBy("AuthWsService");
        userClient.addUserRole(user.getUserId(), relation, null);
    }

    private void recordFailedLogin(String username, String reason) {
        AuditLoginLog loginLog = new AuditLoginLog();
        loginLog.setUsername(username);
        loginLog.setLoginTime(LocalDateTime.now());
        loginLog.setLoginResult("FAILED");
        loginLog.setFailureReason(reason);
        safeCreateAuditLog(loginLog);
    }

    private RoleAggregation aggregateRoles(Long userId) {
        if (userId == null) {
            return RoleAggregation.empty();
        }
        try {
            List<SysUserRole> relations = safeListUserRoles(userId);
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
                SysRole role = safeGetRoleById(relation.getRoleId().longValue());
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

    private SysUser safeGetByUsername(String username) {
        if (!StringUtils.hasText(username)) {
            return null;
        }
        try {
            return userClient.getByUsername(username);
        } catch (FeignException.NotFound ex) {
            return null;
        } catch (FeignException ex) {
            logger.log(Level.WARNING, "Failed to fetch user by username=" + username, ex);
            return null;
        }
    }

    private SysRole safeGetRoleById(Long roleId) {
        if (roleId == null) {
            return null;
        }
        try {
            return roleClient.getById(roleId);
        } catch (FeignException.NotFound ex) {
            return null;
        } catch (FeignException ex) {
            logger.log(Level.WARNING, "Failed to fetch role by id=" + roleId, ex);
            return null;
        }
    }

    private SysRole safeGetRoleByCode(String roleCode) {
        if (!StringUtils.hasText(roleCode)) {
            return null;
        }
        try {
            return roleClient.getByCode(roleCode);
        } catch (FeignException.NotFound ex) {
            return null;
        } catch (FeignException ex) {
            logger.log(Level.WARNING, "Failed to fetch role by code=" + roleCode, ex);
            return null;
        }
    }

    private List<SysUserRole> safeListUserRoles(Long userId) {
        if (userId == null) {
            return List.of();
        }
        try {
            return userClient.listUserRoles(userId, 1, AuthWsService.MAX_ROLE_PAGE_SIZE);
        } catch (FeignException.NotFound ex) {
            return List.of();
        } catch (FeignException ex) {
            logger.log(Level.WARNING, "Failed to fetch user roles for userId=" + userId, ex);
            return List.of();
        }
    }

    private void safeCreateAuditLog(AuditLoginLog loginLog) {
        if (loginLog == null) {
            return;
        }
        try {
            auditLogClient.createLoginLog(loginLog, null);
        } catch (FeignException ex) {
            logger.log(Level.WARNING, "Failed to create audit login log", ex);
        }
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
