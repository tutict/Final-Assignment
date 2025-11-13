package com.tutict.finalassignmentbackend.config.login.jwt;

import com.tutict.finalassignmentbackend.enums.DataScope;
import com.tutict.finalassignmentbackend.enums.RoleType;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;

import javax.crypto.SecretKey;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());

    @Value("${jwt.secret.key}")
    private String base64Secret;

    private SecretKey secretKey;

    private static final Map<String, RoleMetadata> ROLE_SCHEMA;

    static {
        Map<String, RoleMetadata> schema = new LinkedHashMap<>();
        schema.put("SUPER_ADMIN", new RoleMetadata(RoleType.SYSTEM, DataScope.ALL));
        schema.put("ADMIN", new RoleMetadata(RoleType.SYSTEM, DataScope.ALL));
        schema.put("TRAFFIC_POLICE", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        schema.put("FINANCE", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        schema.put("APPEAL_REVIEWER", new RoleMetadata(RoleType.BUSINESS, DataScope.DEPARTMENT));
        ROLE_SCHEMA = Collections.unmodifiableMap(schema);
    }

    @PostConstruct
    public void init() {
        // 将 Base64 编码的密钥解码为 byte 数组
        byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
        // 使用 Keys 工具类生成用于 HMACSHA256 的 SecretKey
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
        LOG.info("TokenProvider initialized with HS256 secret key");
    }

    /**
     * 创建 JWT 令牌，并将角色作为 claim 存入
     *
     * @param username 用户名（主体）
     * @param roles    用户角色，如 "USER" 或 "ADMIN"，多个角色以逗号分隔
     * @return 生成的 JWT 令牌
     */
    public String createToken(String username, String roles) {
        if (validateRoleCodes(roles)) {
            String normalizedRoles = String.join(",", normalizeRoleCodes(roles));

            long now = System.currentTimeMillis();
            Date expirationDate = new Date(now + 86400000L); // 令牌有效期 24 小时

            return Jwts.builder()
                    .subject(username)
                    .claim("roles", normalizedRoles) // 将角色加入到 token 中
                    .issuedAt(new Date(now))
                    .expiration(expirationDate)
                    .signWith(secretKey)
                    .compact();
        }
        throw new IllegalArgumentException("Invalid role codes provided for token creation");
    }

    /**
     * 创建增强的 JWT 令牌，包含角色编码、角色类型和数据权限范围
     *
     * @param username  用户名（主体）
     * @param roleCodes 角色编码列表，多个角色以逗号分隔
     * @param roleTypes 角色类型列表，多个类型以逗号分隔
     * @param dataScope 数据权限范围
     * @return 生成的 JWT 令牌
     */
    public String createEnhancedToken(String username, String roleCodes, String roleTypes, String dataScope) {
        if (!validateRoleClaims(roleCodes, roleTypes, dataScope)) {
            throw new IllegalArgumentException("Role claims do not match the database schema");
        }
        String normalizedRoles = String.join(",", normalizeRoleCodes(roleCodes));

        long now = System.currentTimeMillis();
        Date expirationDate = new Date(now + 86400000L); // 令牌有效期 24 小时

        return Jwts.builder()
                .subject(username)
                .claim("roles", normalizedRoles)
                .claim("roleTypes", roleTypes)
                .claim("dataScope", dataScope)
                .issuedAt(new Date(now))
                .expiration(expirationDate)
                .signWith(secretKey)
                .compact();
    }

    /**
     * 验证 JWT 令牌
     *
     * @param token 令牌字符串
     * @return 若令牌有效返回 true，否则返回 false
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token);
            LOG.log(Level.INFO, "Token validated successfully: " + token);
            return true;
        } catch (JwtException e) {
            LOG.log(Level.WARNING, "Invalid token: " + e.getMessage(), e);
            return false;
        }
    }

    /**
     * 从 JWT 中提取角色列表
     *
     * @param token 令牌字符串
     * @return 角色列表，例如 ["ROLE_USER", "ROLE_ADMIN"]
     */
    public List<String> extractRoles(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            String roles = claims.get("roles", String.class);
            if (roles != null && !roles.isEmpty()) {
                return normalizeRoleCodes(roles).stream()
                        .filter(this::isRoleDefined)
                        .map(role -> "ROLE_" + role)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (JwtException e) {
            LOG.log(Level.WARNING, "Failed to extract roles from token: " + e.getMessage(), e);
            return List.of();
        }
    }

    public String getUsernameFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.getSubject();
    }

    /**
     * 从 JWT 中提取角色类型列表
     *
     * @param token 令牌字符串
     * @return 角色类型枚举列表
     */
    public List<RoleType> extractRoleTypes(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            String roleTypes = claims.get("roleTypes", String.class);
            if (roleTypes != null && !roleTypes.isEmpty()) {
                return Arrays.stream(roleTypes.split(","))
                        .map(String::trim)
                        .map(RoleType::fromCode)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
            }
            return List.of();
        } catch (JwtException e) {
            LOG.log(Level.WARNING, "Failed to extract role types from token: " + e.getMessage(), e);
            return List.of();
        }
    }

    /**
     * 从 JWT 中提取数据权限范围
     *
     * @param token 令牌字符串
     * @return 数据权限范围枚举，如果未设置则返回 null
     */
    public DataScope extractDataScope(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            String dataScope = claims.get("dataScope", String.class);
            return DataScope.fromCode(dataScope);
        } catch (JwtException e) {
            LOG.log(Level.WARNING, "Failed to extract data scope from token: " + e.getMessage(), e);
            return null;
        }
    }

    /**
     * 检查用户是否具有指定的角色类型
     *
     * @param token    令牌字符串
     * @param roleType 要检查的角色类型
     * @return 如果用户具有该角色类型则返回 true
     */
    public boolean hasRoleType(String token, RoleType roleType) {
        List<RoleType> roleTypes = extractRoleTypes(token);
        return roleTypes.contains(roleType);
    }

    /**
     * 检查用户是否具有系统角色
     *
     * @param token 令牌字符串
     * @return 如果用户具有系统角色则返回 true
     */
    public boolean hasSystemRole(String token) {
        return hasRoleType(token, RoleType.SYSTEM);
    }

    /**
     * 检查用户是否具有业务角色
     *
     * @param token 令牌字符串
     * @return 如果用户具有业务角色则返回 true
     */
    public boolean hasBusinessRole(String token) {
        return hasRoleType(token, RoleType.BUSINESS);
    }

    /**
     * 检查用户的数据权限是否包含指定的权限范围
     *
     * @param token              令牌字符串
     * @param requiredDataScope 需要的数据权限范围
     * @return 如果用户的数据权限包含所需权限则返回 true
     */
    public boolean hasDataScopePermission(String token, DataScope requiredDataScope) {
        DataScope userDataScope = extractDataScope(token);
        if (userDataScope == null) {
            return false;
        }
        return userDataScope.includes(requiredDataScope);
    }

    /**
     * 验证角色编码列表的有效性
     *
     * @param roleCodes 角色编码字符串，多个角色以逗号分隔
     * @return 如果所有角色编码都不为空则返回 true
     */
    public boolean validateRoleCodes(String roleCodes) {
        List<String> normalized = normalizeRoleCodes(roleCodes);
        if (normalized.isEmpty()) {
            return false;
        }
        boolean valid = normalized.stream().allMatch(this::isRoleDefined);
        if (!valid) {
            LOG.log(Level.WARNING, "Detected undefined role codes: {0}", normalized);
        }
        return valid;
    }

    /**
     * 同时校验角色编码、类型以及数据权限是否符合数据库模型
     *
     * @param roleCodes 角色编码列表
     * @param roleTypes 角色类型列表
     * @param dataScope 数据权限范围
     * @return 如果所有声明与数据库 schema 匹配则返回 true
     */
    public boolean validateRoleClaims(String roleCodes, String roleTypes, String dataScope) {
        if (!validateRoleCodes(roleCodes)) {
            return false;
        }
        if (!validateRoleTypes(roleTypes) || !validateDataScope(dataScope)) {
            return false;
        }

        DataScope requestedScope = DataScope.fromCode(dataScope);
        if (requestedScope == null) {
            return false;
        }

        Set<RoleType> requestedTypes = Arrays.stream(roleTypes.split(","))
                .map(String::trim)
                .map(RoleType::fromCode)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        for (String roleCode : normalizeRoleCodes(roleCodes)) {
            RoleMetadata metadata = ROLE_SCHEMA.get(roleCode);
            if (metadata == null) {
                LOG.log(Level.WARNING, "Role {0} not defined in schema", roleCode);
                return false;
            }
            if (!requestedTypes.contains(metadata.getRoleType())) {
                LOG.log(Level.WARNING,
                        "Role type {0} missing from claim for role {1}",
                        new Object[]{metadata.getRoleType().getCode(), roleCode});
                return false;
            }
            if (!requestedScope.includes(metadata.getDataScope())) {
                LOG.log(Level.WARNING,
                        "Data scope {0} does not cover required scope {1} for role {2}",
                        new Object[]{requestedScope.getCode(), metadata.getDataScope().getCode(), roleCode});
                return false;
            }
        }

        return true;
    }

    /**
     * 验证角色类型列表的有效性
     *
     * @param roleTypes 角色类型字符串，多个类型以逗号分隔
     * @return 如果所有角色类型都有效则返回 true
     */
    public boolean validateRoleTypes(String roleTypes) {
        if (roleTypes == null || roleTypes.trim().isEmpty()) {
            return false;
        }
        return Arrays.stream(roleTypes.split(","))
                .map(String::trim)
                .allMatch(RoleType::isValid);
    }

    /**
     * 验证数据权限范围的有效性
     *
     * @param dataScope 数据权限范围代码
     * @return 如果数据权限范围有效则返回 true
     */
    public boolean validateDataScope(String dataScope) {
        return DataScope.isValid(dataScope);
    }
    private List<String> normalizeRoleCodes(String roleCodes) {
        if (roleCodes == null) {
            return List.of();
        }
        return Arrays.stream(roleCodes.split(","))
                .map(code -> code.trim().toUpperCase(Locale.ROOT))
                .filter(code -> !code.isEmpty())
                .collect(Collectors.toList());
    }

    private boolean isRoleDefined(String roleCode) {
        return ROLE_SCHEMA.containsKey(roleCode);
    }

    @Getter
    private static final class RoleMetadata {
        private final RoleType roleType;
        private final DataScope dataScope;

        private RoleMetadata(RoleType roleType, DataScope dataScope) {
            this.roleType = roleType;
            this.dataScope = dataScope;
        }

    }
}
