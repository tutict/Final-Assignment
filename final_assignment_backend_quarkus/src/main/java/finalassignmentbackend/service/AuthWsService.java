package finalassignmentbackend.service;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.AuditLoginLog;
import finalassignmentbackend.entity.SysRole;
import finalassignmentbackend.entity.SysUser;
import finalassignmentbackend.entity.SysUserRole;
import finalassignmentbackend.enums.DataScope;
import finalassignmentbackend.enums.RoleType;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@ApplicationScoped
@RegisterForReflection
public class AuthWsService {

    private static final Logger logger = Logger.getLogger(AuthWsService.class.getName());
    private static final int MAX_ROLE_PAGE_SIZE = 100;

    @Inject
    TokenProvider tokenProvider;

    @Inject
    AuditLoginLogService auditLoginLogService;

    @Inject
    SysUserService sysUserService;

    @Inject
    SysRoleService sysRoleService;

    @Inject
    SysUserRoleService sysUserRoleService;

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

            boolean claimsSupported = tokenProvider.validateRoleClaims(roleCodesCsv, roleTypesCsv, dataScopeCode);

            String jwtToken;
            if (claimsSupported) {
                jwtToken = tokenProvider.createEnhancedToken(user.getUsername(), roleCodesCsv, roleTypesCsv, dataScopeCode);
            } else {
                logger.warning(() -> String.format("Role claims incomplete, fallback to basic token for user=%s", user.getUsername()));
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
    @WsAction(service = "AuthWsService", action = "registerUser")
    public String registerUser(RegisterRequest registerRequest) {
        validateRegisterRequest(registerRequest);
        logger.info(() -> String.format("Attempting to register user: %s", registerRequest.getUsername()));

        if (sysUserService.findByUsername(registerRequest.getUsername()) != null) {
            logger.severe(() -> String.format("Username already exists: %s", registerRequest.getUsername()));
            throw new RuntimeException("Username already exists: " + registerRequest.getUsername());
        }

        String idempotencyKey = registerRequest.getIdempotencyKey();
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            SysUser probe = new SysUser();
            probe.setUsername(registerRequest.getUsername());
            sysUserService.checkAndInsertIdempotency(idempotencyKey, probe, "create");
        }

        SysUser newUser = new SysUser();
        newUser.setUsername(registerRequest.getUsername());
        newUser.setPassword(registerRequest.getPassword());
        newUser.setStatus("Active");
        newUser.setCreatedAt(LocalDateTime.now());
        newUser.setUpdatedAt(LocalDateTime.now());
        sysUserService.createSysUser(newUser);

        SysUser savedUser = sysUserService.findByUsername(registerRequest.getUsername());
        if (savedUser == null) {
            throw new RuntimeException("User creation failed");
        }

        SysRole role = resolveOrCreateRole(registerRequest.getRole());
        assignRole(savedUser, role);

        logger.info(() -> String.format("User registered successfully: %s", registerRequest.getUsername()));
        return "CREATED";
    }

    @WsAction(service = "AuthWsService", action = "getAllUsers")
    @CacheResult(cacheName = "userCache")
    public List<SysUser> getAllUsers() {
        logger.info("[WS] Fetching all users");
        List<SysUser> users = sysUserService.findAll();
        if (users.isEmpty()) {
            logger.warning("No users found in the system");
        }
        return users;
    }

    private void validateLoginRequest(LoginRequest loginRequest) {
        Objects.requireNonNull(loginRequest, "Login request must not be null");
        if (loginRequest.getUsername() == null || loginRequest.getUsername().isBlank()) {
            throw new RuntimeException("Invalid username");
        }
        if (loginRequest.getPassword() == null || loginRequest.getPassword().isBlank()) {
            throw new RuntimeException("Invalid password");
        }
    }

    private void validateRegisterRequest(RegisterRequest registerRequest) {
        Objects.requireNonNull(registerRequest, "Register request must not be null");
        if (registerRequest.getUsername() == null || registerRequest.getUsername().isBlank()) {
            throw new IllegalArgumentException("Username must not be blank");
        }
        if (registerRequest.getPassword() == null || registerRequest.getPassword().isBlank()) {
            throw new IllegalArgumentException("Password must not be blank");
        }
    }

    private boolean authenticateUser(SysUser user, String password) {
        return Objects.equals(user.getPassword(), password);
    }

    private SysRole resolveOrCreateRole(String requestedRole) {
        String roleCode = (requestedRole == null || requestedRole.isBlank()) ? "USER" : requestedRole;
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
                if (role.getRoleName() != null && !role.getRoleName().isBlank()) {
                    roleNames.add(role.getRoleName());
                }
                String roleCode = resolveRoleCode(role);
                if (roleCode != null && !roleCode.isBlank()) {
                    roleCodes.add(roleCode);
                }
                String roleType = resolveRoleType(role);
                if (roleType != null && !roleType.isBlank()) {
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
        String code = (role.getRoleCode() == null || role.getRoleCode().isBlank())
                ? role.getRoleName()
                : role.getRoleCode();
        return code == null ? null : code.trim().toUpperCase(Locale.ROOT);
    }

    private String resolveRoleType(SysRole role) {
        if (role == null || role.getRoleType() == null || role.getRoleType().isBlank()) {
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
