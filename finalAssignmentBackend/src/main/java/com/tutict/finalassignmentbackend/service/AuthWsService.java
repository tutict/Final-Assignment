package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.dto.request.RefreshRequest;
import com.tutict.finalassignmentbackend.dto.response.TokenResponse;
import com.tutict.finalassignmentbackend.entity.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.SysRole;
import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.entity.SysUserRole;
import com.tutict.finalassignmentbackend.enums.DataScope;
import com.tutict.finalassignmentbackend.enums.RoleType;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
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
    private final AuditLoginLogService auditLoginLogService;
    private final SysUserService sysUserService;
    private final SysRoleService sysRoleService;
    private final SysUserRoleService sysUserRoleService;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokenService;
    private final TokenBlacklistService tokenBlacklistService;

    @Autowired
    public AuthWsService(TokenProvider tokenProvider,
                         AuditLoginLogService auditLoginLogService,
                         SysUserService sysUserService,
                         SysRoleService sysRoleService,
                         SysUserRoleService sysUserRoleService,
                         PasswordEncoder passwordEncoder,
                         RefreshTokenService refreshTokenService,
                         TokenBlacklistService tokenBlacklistService) {
        this.tokenProvider = tokenProvider;
        this.auditLoginLogService = auditLoginLogService;
        this.sysUserService = sysUserService;
        this.sysRoleService = sysRoleService;
        this.sysUserRoleService = sysUserRoleService;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokenService = refreshTokenService;
        this.tokenBlacklistService = tokenBlacklistService;
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "login")
    public Map<String, Object> login(LoginRequest loginRequest) {
        validateLoginRequest(loginRequest);

        logger.info(() -> String.format("[WS] Attempting to authenticate user: %s", loginRequest.getUsername()));
        SysUser user = sysUserService.findByUsername(loginRequest.getUsername());

        if (user != null && authenticateUser(user, loginRequest.getPassword())) {
            RoleAggregation aggregation = requireRoles(user, loginRequest.getUsername());
            List<String> roles = aggregation.getRoleNames();
            String rolesString = String.join(",", roles);
            String jwtToken = issueAccessToken(user, aggregation, rolesString);
            String refreshToken = refreshTokenService.createRefreshToken(user.getUserId());
            String dataScopeCode = aggregation.getDataScope().getCode();

            boolean systemRole = tokenProvider.hasSystemRole(jwtToken);
            boolean businessRole = tokenProvider.hasBusinessRole(jwtToken);
            boolean hasDepartmentScope = tokenProvider.hasDataScopePermission(jwtToken, DataScope.DEPARTMENT);

            logger.info(() -> String.format("User authenticated successfully (WS): %s with roles: %s",
                    loginRequest.getUsername(), rolesString));

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("jwtToken", jwtToken);
            result.put("accessToken", jwtToken);
            result.put("refreshToken", refreshToken);
            result.put("tokenType", "Bearer");
            result.put("expiresIn", tokenProvider.getAccessTokenExpirationSeconds());
            result.put("refreshTokenExpiresIn", refreshTokenService.getRefreshTokenExpirationSeconds());
            result.put("username", user.getUsername());
            result.put("roles", roles);
            result.put("roleCodes", aggregation.getRoleCodes());
            result.put("roleTypes", aggregation.getRoleTypes());
            result.put("dataScope", dataScopeCode);
            result.put("systemRole", systemRole);
            result.put("businessRole", businessRole);
            result.put("departmentScope", hasDepartmentScope);
            return result;
        }

        logger.severe(() -> String.format("Authentication failed (WS) for user: %s", loginRequest.getUsername()));
        recordFailedLogin(loginRequest.getUsername(), "INVALID_CREDENTIALS");
        throw new BadCredentialsException("Invalid username or password.");
    }

    @Transactional
    public TokenResponse refresh(RefreshRequest request) {
        if (request == null || !StringUtils.hasText(request.getRefreshToken())) {
            throw new BadCredentialsException("Refresh token is required");
        }
        Long userId = refreshTokenService.validateRefreshToken(request.getRefreshToken());
        SysUser user = sysUserService.findById(userId);
        if (user == null) {
            throw new BadCredentialsException("Refresh token user no longer exists");
        }

        RoleAggregation aggregation = requireRoles(user, user.getUsername());
        String accessToken = issueAccessToken(user, aggregation, String.join(",", aggregation.getRoleNames()));
        String newRefreshToken = refreshTokenService.rotateRefreshToken(userId, request.getRefreshToken());

        return TokenResponse.builder()
                .accessToken(accessToken)
                .refreshToken(newRefreshToken)
                .expiresIn(tokenProvider.getAccessTokenExpirationSeconds())
                .tokenType("Bearer")
                .build();
    }

    @Transactional
    public void logout(String username, String bearerToken) {
        if (!StringUtils.hasText(username)) {
            throw new BadCredentialsException("Authenticated user is required");
        }
        SysUser user = sysUserService.findByUsername(username);
        if (user == null) {
            throw new BadCredentialsException("Authenticated user no longer exists");
        }

        refreshTokenService.revokeUserTokens(user.getUserId());

        String token = extractBearerToken(bearerToken);
        long remaining = tokenProvider.getExpirationMs(token);
        tokenBlacklistService.blacklist(token, remaining);
    }

    @Transactional
    @CacheEvict(cacheNames = {"AuthCache", "usernameExistsCache"}, allEntries = true)
    @WsAction(service = "AuthWsService", action = "registerUser")
    public String registerUser(RegisterRequest registerRequest) {
        validateRegisterRequest(registerRequest);
        logger.info(() -> String.format("Registering user: %s", registerRequest.getUsername()));

        if (sysUserService.isUsernameExists(registerRequest.getUsername())) {
            throw new RuntimeException("Username already exists: " + registerRequest.getUsername());
        }

        String idempotencyKey = registerRequest.getIdempotencyKey();
        if (StringUtils.hasText(idempotencyKey)) {
            SysUser probe = new SysUser();
            probe.setUsername(registerRequest.getUsername());
            try {
                sysUserService.checkAndInsertIdempotency(idempotencyKey, probe, "create");
            } catch (RuntimeException e) {
                logger.log(Level.WARNING, "Duplicate register request detected, key={0}", idempotencyKey);
                throw new RuntimeException("Register request duplicated", e);
            }
        }

        SysUser newUser = new SysUser();
        newUser.setUsername(registerRequest.getUsername());
        newUser.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        newUser.setSalt(null);
        newUser.setStatus("Active");
        newUser.setCreatedAt(LocalDateTime.now());
        newUser.setUpdatedAt(LocalDateTime.now());
        sysUserService.createSysUser(newUser);

        SysUser savedUser = sysUserService.findByUsername(registerRequest.getUsername());
        if (savedUser == null) {
            throw new RuntimeException("User registration failed: user was not persisted");
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
        List<SysUser> users = sysUserService.getAllUsers();
        if (users.isEmpty()) {
            logger.warning("No users found in the system");
        }
        return users;
    }

    private RoleAggregation requireRoles(SysUser user, String usernameForLog) {
        RoleAggregation aggregation = aggregateRoles(user.getUserId());
        if (aggregation.getRoleNames().isEmpty()) {
            logger.severe(() -> String.format("No roles found for user: %s", usernameForLog));
            recordFailedLogin(usernameForLog, "NO_ROLES_ASSIGNED");
            throw new RuntimeException("No roles assigned to user.");
        }
        return aggregation;
    }

    private String issueAccessToken(SysUser user, RoleAggregation aggregation, String rolesString) {
        String roleCodesCsv = String.join(",", aggregation.getRoleCodes());
        String roleTypesCsv = String.join(",", aggregation.getRoleTypes());
        String dataScopeCode = aggregation.getDataScope().getCode();

        boolean claimsSupported = StringUtils.hasText(roleCodesCsv)
                && StringUtils.hasText(roleTypesCsv)
                && tokenProvider.validateRoleClaims(roleCodesCsv, roleTypesCsv, dataScopeCode);

        if (claimsSupported) {
            return tokenProvider.createEnhancedToken(user.getUsername(), roleCodesCsv, roleTypesCsv, dataScopeCode);
        }
        logger.warning(() -> String.format("Falling back to basic JWT claims for user=%s", user.getUsername()));
        return tokenProvider.createToken(user.getUsername(), rolesString);
    }

    private String extractBearerToken(String bearerToken) {
        if (!StringUtils.hasText(bearerToken) || !bearerToken.startsWith("Bearer ")) {
            throw new BadCredentialsException("Bearer access token is required");
        }
        return bearerToken.substring(7);
    }

    private void validateLoginRequest(LoginRequest loginRequest) {
        Objects.requireNonNull(loginRequest, "Login request must not be null");
        if (!StringUtils.hasText(loginRequest.getUsername())) {
            throw new RuntimeException("Invalid username");
        }
        if (!StringUtils.hasText(loginRequest.getPassword())) {
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
        return StringUtils.hasText(user.getPassword()) && passwordEncoder.matches(password, user.getPassword());
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
