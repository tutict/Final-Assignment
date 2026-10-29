package finalassignmentbackend.rag.elasticsearch;

import finalassignmentbackend.rag.access.RagAclPolicy;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;
import jakarta.json.JsonReader;
import jakarta.json.JsonString;
import jakarta.json.JsonValue;

import java.io.StringReader;
import java.util.Locale;

/**
 * 把 MySQL 中的文档与分块翻译成 ES 文档。
 *
 * <p>ACL 明细只存在于 {@code rag_document.metadata_json}，没有独立列，因此这里负责把
 * metadata 里的角色/用户/部门列表抽出来写成 keyword 字段，供 ES 侧粗过滤使用；
 * 检索侧仍会用 MySQL 里的 metadata 做严格判定，ES 过滤只是减少候选量。
 */
@ApplicationScoped
public class RagChunkSourceFactory {

    /** 角色列表的候选键名，兼容驼峰与下划线两种写法。 */
    public static final String[] ROLE_KEYS = RagAclPolicy.ROLE_KEYS;
    /** 用户列表的候选键名。 */
    public static final String[] USER_KEYS = RagAclPolicy.USER_KEYS;
    /** 部门列表的候选键名。 */
    public static final String[] DEPARTMENT_KEYS = RagAclPolicy.DEPARTMENT_KEYS;

    public JsonObject build(RagDocument document, RagChunk chunk, float[] vector, String provider, String model) {
        JsonObject metadata = metadata(document.getMetadataJson());
        JsonObjectBuilder source = Json.createObjectBuilder();
        add(source, "chunk_id", chunk.getId());
        add(source, "document_id", document.getId());
        add(source, "content", chunk.getContent());
        add(source, "title", document.getTitle());
        add(source, "source_type", document.getSourceType());
        add(source, "source_table", document.getSourceTable());
        add(source, "source_id", document.getSourceId());
        add(source, "source_version", document.getSourceVersion());
        add(source, "source_field", chunk.getSourceField());
        add(source, "route", document.getRoute());
        // scope 缺省即 PUBLIC：ES 侧用 term 过滤 ACL，缺省值必须显式写出来才筛得到。
        add(source, "acl_scope", scope(document.getAclScope()));
        source.add("acl_roles", list(metadata, ROLE_KEYS));
        source.add("acl_user_ids", list(metadata, USER_KEYS));
        source.add("acl_departments", list(metadata, DEPARTMENT_KEYS));
        source.add("metadata", metadata);
        add(source, "embedding_provider", provider);
        add(source, "embedding_model", model);
        source.add("embedding", toArray(vector));
        return source.build();
    }

    /** 解析 metadata_json；解析失败时保留原文，避免整篇文档无法入库。 */
    public JsonObject metadata(String metadataJson) {
        if (metadataJson == null || metadataJson.isBlank()) {
            return Json.createObjectBuilder().build();
        }
        try (JsonReader reader = Json.createReader(new StringReader(metadataJson))) {
            return reader.readObject();
        } catch (Exception error) {
            return Json.createObjectBuilder()
                    .add("rawMetadata", metadataJson)
                    .add("metadataParseError", String.valueOf(error.getMessage()))
                    .build();
        }
    }

    /** 取第一个命中的键对应的字符串列表。 */
    public JsonArray list(JsonObject metadata, String... keys) {
        JsonArrayBuilder builder = Json.createArrayBuilder();
        if (metadata == null) {
            return builder.build();
        }
        for (String key : keys) {
            if (!metadata.containsKey(key)) {
                continue;
            }
            JsonValue value = metadata.get(key);
            if (value.getValueType() == JsonValue.ValueType.ARRAY) {
                for (JsonValue item : metadata.getJsonArray(key)) {
                    append(builder, item);
                }
            } else {
                append(builder, value);
            }
            break;
        }
        return builder.build();
    }

    private static void append(JsonArrayBuilder builder, JsonValue item) {
        if (item == null || item.getValueType() == JsonValue.ValueType.NULL) {
            return;
        }
        if (item.getValueType() == JsonValue.ValueType.STRING) {
            String text = ((JsonString) item).getString();
            if (!text.isBlank()) {
                builder.add(text);
            }
            return;
        }
        if (item.getValueType() == JsonValue.ValueType.ARRAY) {
            for (JsonValue nested : (JsonArray) item) {
                append(builder, nested);
            }
            return;
        }
        builder.add(item.toString());
    }

    private static JsonArray toArray(float[] vector) {
        JsonArrayBuilder builder = Json.createArrayBuilder();
        if (vector != null) {
            for (float value : vector) {
                builder.add((double) value);
            }
        }
        return builder.build();
    }

    private static void add(JsonObjectBuilder builder, String name, String value) {
        if (value == null) {
            builder.add(name, JsonValue.NULL);
            return;
        }
        builder.add(name, value);
    }

    private static String scope(String aclScope) {
        return aclScope == null || aclScope.isBlank() ? "PUBLIC" : aclScope.trim().toUpperCase(Locale.ROOT);
    }
}
