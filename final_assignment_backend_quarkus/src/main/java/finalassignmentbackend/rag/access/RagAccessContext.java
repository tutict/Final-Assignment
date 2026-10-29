package finalassignmentbackend.rag.access;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;

/**
 * 检索请求的调用者身份。
 *
 * <p>身份只能来自服务端：请求体里的角色不可信，检索链路只认这里构造出来的上下文。
 */
public record RagAccessContext(String userId, Set<String> roles, String department) {

    /** 已知角色码：JWT 里出现的角色只有这些，判定时按这些逐一询问安全上下文。 */
    public static final java.util.List<String> KNOWN_ROLES = java.util.List.of(
            "SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER", "USER");

    private static final Set<String> SYSTEM_ROLES = Set.of("SUPER_ADMIN", "ADMIN");
    private static final Set<String> DEPARTMENT_ROLES = Set.of("TRAFFIC_POLICE", "FINANCE", "APPEAL_REVIEWER");

    public RagAccessContext {
        userId = blankToNull(userId);
        roles = roles == null ? Set.of() : Collections.unmodifiableSet(new LinkedHashSet<>(roles));
        department = blankToNull(department);
    }

    /**
     * 构造检索身份，并按 Spring 参考实现推导部门归属。
     *
     * <p>系统角色对应 ALL，业务角色对应 DEPARTMENT，其余角色没有部门身份。
     */
    public static RagAccessContext of(String userId, Collection<String> roles) {
        Set<String> normalized = normalizeRoles(roles);
        return new RagAccessContext(userId, normalized, departmentOf(normalized));
    }

    static Set<String> normalizeRoles(Collection<String> roles) {
        Set<String> normalized = new LinkedHashSet<>();
        if (roles == null) {
            return normalized;
        }
        for (String role : roles) {
            if (role == null) {
                continue;
            }
            String value = role.trim().toUpperCase(Locale.ROOT);
            if (value.startsWith("ROLE_")) {
                value = value.substring("ROLE_".length());
            }
            if (!value.isBlank()) {
                normalized.add(value);
            }
        }
        return normalized;
    }

    static String departmentOf(Set<String> roles) {
        for (String role : roles) {
            if (SYSTEM_ROLES.contains(role)) {
                return "ALL";
            }
        }
        for (String role : roles) {
            if (DEPARTMENT_ROLES.contains(role)) {
                return "DEPARTMENT";
            }
        }
        return null;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
