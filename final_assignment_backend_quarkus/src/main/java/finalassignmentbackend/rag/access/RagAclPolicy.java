package finalassignmentbackend.rag.access;

import finalassignmentbackend.rag.entity.RagDocument;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.json.JsonReader;
import jakarta.json.JsonString;
import jakarta.json.JsonValue;

import java.io.StringReader;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;

/**
 * 严格的可见性判定。
 *
 * <p>{@code acl_scope} 只说明「按什么维度限制」，具体名单在 {@code rag_document.metadata_json} 里，
 * 因此判定必须同时看 scope 与 metadata 中的角色、用户、部门名单。名单缺失时一律拒绝，
 * 解析失败的 metadata 同样按「没有名单」处理。
 */
public final class RagAclPolicy {

    /** 角色名单的候选键名，兼容驼峰与下划线两种写法。 */
    public static final String[] ROLE_KEYS = {"roles", "aclRoles", "acl_roles"};
    /** 用户名单的候选键名。 */
    public static final String[] USER_KEYS = {"userIds", "userId", "aclUserIds", "acl_user_ids"};
    /** 部门名单的候选键名。 */
    public static final String[] DEPARTMENT_KEYS = {"departments", "department", "aclDepartments", "acl_departments"};

    private RagAclPolicy() {
    }

    /** 文档的可见性判定依据。 */
    public record DocumentAcl(String scope, Set<String> roles, Set<String> userIds, Set<String> departments) {

        public DocumentAcl {
            scope = scope == null || scope.isBlank() ? "PUBLIC" : scope.trim().toUpperCase(Locale.ROOT);
            roles = copy(roles);
            userIds = copy(userIds);
            departments = copy(departments);
        }
    }

    /** 从数据库里的文档解析可见性依据。 */
    public static DocumentAcl parse(RagDocument document) {
        if (document == null) {
            return new DocumentAcl("PUBLIC", Set.of(), Set.of(), Set.of());
        }
        JsonObject metadata = metadata(document.getMetadataJson());
        return new DocumentAcl(
                document.getAclScope(),
                values(metadata, ROLE_KEYS),
                values(metadata, USER_KEYS),
                values(metadata, DEPARTMENT_KEYS)
        );
    }

    /** 判定调用者能否看到该文档。 */
    public static boolean allows(DocumentAcl acl, RagAccessContext context) {
        if (acl == null) {
            return false;
        }
        RagAccessContext effective = context == null
                ? new RagAccessContext(null, Set.of(), null)
                : context;
        return switch (acl.scope()) {
            case "PUBLIC" -> true;
            case "ROLE" -> intersects(effective.roles(), acl.roles());
            case "USER" -> effective.userId() != null && acl.userIds().contains(effective.userId());
            case "DEPARTMENT" -> effective.department() != null && acl.departments().contains(effective.department());
            default -> false;
        };
    }

    /** 解析 metadata_json；解析失败按空对象处理，避免整篇文档因脏数据而失去可见性约束。 */
    public static JsonObject metadata(String metadataJson) {
        if (metadataJson == null || metadataJson.isBlank()) {
            return Json.createObjectBuilder().build();
        }
        try (JsonReader reader = Json.createReader(new StringReader(metadataJson))) {
            return reader.readObject();
        } catch (Exception error) {
            return Json.createObjectBuilder().build();
        }
    }

    /** 取第一个命中的键对应的字符串列表。 */
    public static Set<String> values(JsonObject metadata, String... keys) {
        if (metadata == null) {
            return Set.of();
        }
        for (String key : keys) {
            if (!metadata.containsKey(key)) {
                continue;
            }
            JsonValue value = metadata.get(key);
            if (value.getValueType() == JsonValue.ValueType.ARRAY) {
                Set<String> collected = new LinkedHashSet<>();
                metadata.getJsonArray(key).forEach(item -> {
                    String text = asText(item);
                    if (text != null) {
                        collected.add(text);
                    }
                });
                return Collections.unmodifiableSet(collected);
            }
            String text = asText(value);
            return text == null ? Set.of() : Set.of(text);
        }
        return Set.of();
    }

    private static String asText(JsonValue value) {
        if (value == null || value.getValueType() == JsonValue.ValueType.NULL) {
            return null;
        }
        if (value.getValueType() == JsonValue.ValueType.STRING) {
            String text = ((JsonString) value).getString();
            return text.isBlank() ? null : text;
        }
        return value.toString();
    }

    private static boolean intersects(Set<String> left, Set<String> right) {
        return left.stream().anyMatch(right::contains);
    }

    private static Set<String> copy(Collection<String> values) {
        if (values == null || values.isEmpty()) {
            return Set.of();
        }
        Set<String> copy = new LinkedHashSet<>();
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                copy.add(value.trim());
            }
        }
        return Collections.unmodifiableSet(copy);
    }
}
