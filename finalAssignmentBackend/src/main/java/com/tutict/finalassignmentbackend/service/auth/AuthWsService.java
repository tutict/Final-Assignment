package com.tutict.finalassignmentbackend.service.auth;

import com.tutict.finalassignmentbackend.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.dto.mapper.UserResponseMapper;
import com.tutict.finalassignmentbackend.dto.request.RefreshRequest;
import com.tutict.finalassignmentbackend.dto.response.TokenResponse;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.dto.response.UserResponse;
import com.tutict.finalassignmentbackend.entity.audit.AuditLoginLog;
import com.tutict.finalassignmentbackend.entity.driver.DriverInformation;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.admin.SysRole;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.entity.admin.SysUserRole;
import com.tutict.finalassignmentbackend.enums.DataScope;
import com.tutict.finalassignmentbackend.enums.RoleType;
import com.tutict.finalassignmentbackend.exception.EntityNotFoundException;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.service.admin.SysRoleService;
import com.tutict.finalassignmentbackend.service.admin.SysUserRoleService;
import com.tutict.finalassignmentbackend.service.admin.SysUserService;
import com.tutict.finalassignmentbackend.service.audit.AuditLoginLogService;
import com.tutict.finalassignmentbackend.service.driver.DriverInformationService;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.validation.constraints.NotBlank;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class AuthWsService {

    private static final Logger logger = Logger.getLogger(AuthWsService.class.getName());
    private static final int MAX_ROLE_PAGE_SIZE = 100;
    private static final String PUBLIC_REGISTER_ROLE = "USER";
    private static final Set<String> DRIVER_PROFILE_ROLES = Set.of("USER");
    private static final Set<String> STAFF_ROLES = Set.of(
            "SUPER_ADMIN",
            "ADMIN",
            "TRAFFIC_POLICE",
            "FINANCE",
            "APPEAL_REVIEWER"
    );

    private final TokenProvider tokenProvider;
    private final AuditLoginLogService auditLoginLogService;
    private final SysUserService sysUserService;
    private final SysRoleService sysRoleService;
    private final SysUserRoleService sysUserRoleService;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokenService;
    private final TokenBlacklistService tokenBlacklistService;
    private final DriverInformationService driverInformationService;

    @Autowired
    public AuthWsService(TokenProvider tokenProvider,
                         AuditLoginLogService auditLoginLogService,
                         SysUserService sysUserService,
                         SysRoleService sysRoleService,
                         SysUserRoleService sysUserRoleService,
                         SysRequestHistoryMapper sysRequestHistoryMapper,
                         PasswordEncoder passwordEncoder,
                         RefreshTokenService refreshTokenService,
                         TokenBlacklistService tokenBlacklistService,
                         DriverInformationService driverInformationService) {
        this.tokenProvider = tokenProvider;
        this.auditLoginLogService = auditLoginLogService;
        this.sysUserService = sysUserService;
        this.sysRoleService = sysRoleService;
        this.sysUserRoleService = sysUserRoleService;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokenService = refreshTokenService;
        this.tokenBlacklistService = tokenBlacklistService;
        this.driverInformationService = driverInformationService;
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "login", allowAuthenticated = true)
    public Map<String, Object> login(LoginRequest loginRequest) {
        validateLoginRequest(loginRequest);

        logger.info(() -> String.format("[WS] Attempting to authenticate user: %s", loginRequest.getUsername()));
        SysUser user = sysUserService.findByUsername(loginRequest.getUsername());

        if (user != null && authenticateUser(user, loginRequest.getPassword())) {
            RoleAggregation aggregation = requireRoles(user, loginRequest.getUsername());
            List<String> roleNames = aggregation.getRoleNames();
            List<String> roleCodes = aggregation.getRoleCodes();
            String rolesString = String.join(",", roleCodes);
            String jwtToken = issueAccessToken(user, aggregation, rolesString);
            String refreshToken = refreshTokenService.createRefreshToken(user.getUserId());
            String dataScopeCode = aggregation.getDataScope().getCode();
            DriverInformation driver = resolveDriverForUser(user, aggregation);

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
            result.put("authUserId", user.getUserId());
            result.put("driverId", driver != null ? driver.getDriverId() : null);
            result.put("displayName", resolveDisplayName(user));
            result.put("driverName", driver != null ? driver.getName() : null);
            result.put("roles", roleCodes);
            result.put("roleNames", roleNames);
            result.put("roleCodes", roleCodes);
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
    public UserProfileResponse getCurrentUserProfile(String username) {
        if (!StringUtils.hasText(username)) {
            throw new EntityNotFoundException("User not found");
        }

        SysUser user = sysUserService.findByUsername(username);
        if (user == null) {
            throw new EntityNotFoundException("User not found: " + username);
        }

        RoleAggregation aggregation = aggregateRoles(user.getUserId());
        DriverInformation driver = resolveDriverForUser(user, aggregation);

        return UserProfileResponse.builder()
                .authUserId(user.getUserId())
                .username(user.getUsername())
                .displayName(resolveDisplayName(user))
                .email(user.getEmail())
                .phoneNumber(maskPhone(user.getContactNumber()))
                .roles(aggregation.getRoleCodes())
                .driverId(driver != null ? driver.getDriverId() : null)
                .driverName(driver != null ? driver.getName() : null)
                .build();
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
        String accessToken = issueAccessToken(user, aggregation, String.join(",", aggregation.getRoleCodes()));
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
    @WsAction(service = "AuthWsService", action = "registerUser", roles = {"SUPER_ADMIN", "ADMIN"})
    public String registerUser(RegisterRequest registerRequest) {
        validateRegisterRequest(registerRequest);
        logger.info(() -> String.format("Registering user: %s", registerRequest.getUsername()));

        SysRequestHistory registerHistory = null;
        String idempotencyKey = registerRequest.getIdempotencyKey();
        if (StringUtils.hasText(idempotencyKey)) {
            SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
            if (existing != null) {
                return replayRegisterRequest(registerRequest, existing);
            }
            try {
                registerHistory = createRegisterHistory(registerRequest);
            } catch (DataIntegrityViolationException e) {
                SysRequestHistory racingRequest = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
                if (racingRequest != null) {
                    return replayRegisterRequest(registerRequest, racingRequest);
                }
                throw e;
            }
        }

        if (sysUserService.isUsernameExists(registerRequest.getUsername())) {
            throw new RuntimeException("Username already exists: " + registerRequest.getUsername());
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

        SysRole role = resolveOrCreateRole(PUBLIC_REGISTER_ROLE);
        assignRole(savedUser, role);
        driverInformationService.findOrCreateLinkedDriver(savedUser);
        markRegisterHistorySuccess(registerHistory, savedUser.getUserId());

        logger.info(() -> String.format("User registered successfully: %s", registerRequest.getUsername()));
        return "CREATED";
    }

    @CacheEvict(cacheNames = "AuthCache", allEntries = true)
    @WsAction(service = "AuthWsService", action = "getAllUsers", roles = {"SUPER_ADMIN", "ADMIN"})
    public List<UserResponse> getAllUsers() {
        logger.info("[WS] Fetching all users");
        List<SysUser> users = sysUserService.getAllUsers();
        if (users.isEmpty()) {
            logger.warning("No users found in the system");
        }
        return users.stream()
                .map(UserResponseMapper::toResponse)
                .toList();
    }

    private SysRequestHistory createRegisterHistory(RegisterRequest registerRequest) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(registerRequest.getIdempotencyKey());
        history.setRequestMethod("POST");
        history.setRequestUrl("/api/auth/register");
        history.setRequestParams("username=" + truncate(registerRequest.getUsername(), 240));
        history.setBusinessType("AUTH_REGISTER");
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);
        return history;
    }

    private String replayRegisterRequest(RegisterRequest registerRequest, SysRequestHistory history) {
        if (!isRegisterHistory(history)) {
            logger.log(Level.WARNING, "Idempotency key belongs to another operation, key={0}",
                    registerRequest.getIdempotencyKey());
            throw new RuntimeException("Register request duplicated");
        }
        SysUser existingUser = sysUserService.findByUsername(registerRequest.getUsername());
        if (existingUser != null && authenticateUser(existingUser, registerRequest.getPassword())) {
            SysRole role = resolveOrCreateRole(PUBLIC_REGISTER_ROLE);
            ensureRole(existingUser, role);
            driverInformationService.findOrCreateLinkedDriver(existingUser);
            markRegisterHistorySuccess(history, existingUser.getUserId());
            logger.info(() -> String.format(
                    "Replayed idempotent register success for user=%s, key=%s",
                    registerRequest.getUsername(), registerRequest.getIdempotencyKey()));
            return "CREATED";
        }
        logger.log(Level.WARNING, "Duplicate register request detected, key={0}", registerRequest.getIdempotencyKey());
        throw new RuntimeException("Register request duplicated");
    }

    private boolean isRegisterHistory(SysRequestHistory history) {
        return history != null
                && "AUTH_REGISTER".equalsIgnoreCase(history.getBusinessType())
                && "/api/auth/register".equals(history.getRequestUrl());
    }

    private void markRegisterHistorySuccess(SysRequestHistory history, Long userId) {
        if (history == null) {
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(userId);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
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

    private DriverInformation resolveDriverForUser(SysUser user, RoleAggregation aggregation) {
        if (!shouldOwnDriverProfile(aggregation)) {
            return null;
        }
        return driverInformationService.findOrCreateLinkedDriver(user);
    }

    private boolean shouldOwnDriverProfile(RoleAggregation aggregation) {
        if (aggregation == null) {
            return false;
        }
        List<String> roleCodes = aggregation.getRoleCodes();
        if (roleCodes == null || roleCodes.isEmpty()) {
            return false;
        }
        boolean userRole = roleCodes.stream().anyMatch(DRIVER_PROFILE_ROLES::contains);
        boolean staffRole = roleCodes.stream().anyMatch(STAFF_ROLES::contains);
        return userRole && !staffRole;
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

    private String resolveDisplayName(SysUser user) {
        if (user == null) {
            return null;
        }
        return StringUtils.hasText(user.getRealName()) ? user.getRealName() : user.getUsername();
    }

    private String maskPhone(String phoneNumber) {
        if (!StringUtils.hasText(phoneNumber)) {
            return phoneNumber;
        }
        String trimmed = phoneNumber.trim();
        if (trimmed.length() < 7) {
            return trimmed.charAt(0) + "****";
        }
        return trimmed.substring(0, 3) + "****" + trimmed.substring(trimmed.length() - 4);
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
        String roleCode = normalizeRoleCode(StringUtils.hasText(requestedRole) ? requestedRole : "USER");
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

    private void ensureRole(SysUser user, SysRole role) {
        List<SysUserRole> relations = sysUserRoleService.findByUserIdAndRoleId(
                user.getUserId(), role.getRoleId(), 1, 1);
        if (!relations.isEmpty()) {
            return;
        }
        assignRole(user, role);
    }

    private void recordFailedLogin(String username, String reason) {
        AuditLoginLog loginLog = new AuditLoginLog();
        loginLog.setUsername(username);
        loginLog.setLoginTime(LocalDateTime.now());
        loginLog.setLoginResult("Failed");
        loginLog.setFailureReason(reason);
        loginLog.setLoginIp("0.0.0.0");
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
        return StringUtils.hasText(code) ? normalizeRoleCode(code) : null;
    }

    private static String normalizeRoleCode(String roleCode) {
        if (!StringUtils.hasText(roleCode)) {
            return null;
        }
        String normalized = roleCode.trim().toUpperCase(Locale.ROOT);
        if (normalized.startsWith("ROLE_")) {
            return normalized.substring("ROLE_".length());
        }
        return normalized;
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

    private String truncate(String value, int maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
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
        @NotBlank(message = "username must not be blank")
        private String username;
        @NotBlank(message = "password must not be blank")
        private String password;
    }

    @Data
    public static class RegisterRequest {
        @NotBlank(message = "username must not be blank")
        private String username;
        @NotBlank(message = "password must not be blank")
        private String password;
        private String role;
        private String idempotencyKey;
    }
}
