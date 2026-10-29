package finalassignmentbackend.rag.elasticsearch;

import finalassignmentbackend.rag.config.RagProperties;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.json.JsonObject;

import java.time.Instant;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * RAG 索引与别名生命周期管理。
 *
 * <p>索引按需创建，写入始终落到物理索引，检索走别名；别名缺失时补建并标记为写索引，
 * 已存在的别名不被抢占（可能指向别的物理索引）。
 */
@ApplicationScoped
public class RagIndexManager {

    private static final Logger LOG = Logger.getLogger(RagIndexManager.class.getName());

    @Inject ElasticsearchClient client;
    @Inject RagIndexMapping mapping;
    @Inject RagProperties properties;

    private volatile boolean ready;

    public record IndexState(boolean createdIndex, boolean aliasSwitched) {
    }

    /** 迁移结果。 */
    public record MigrationResult(boolean createdIndex, boolean aliasSwitched, String targetIndexName) {
    }

    /** 当前写入的物理索引；迁移后指向新索引。 */
    private volatile String activeIndex;

    /** 幂等地确保索引与别名存在。 */
    public IndexState ensureReady() {
        if (ready) {
            return new IndexState(false, false);
        }
        synchronized (this) {
            if (ready) {
                return new IndexState(false, false);
            }
            // 别名是权威。运维用迁移端点切到新索引后，重启不能把写入拨回配置里的旧索引，
            // 否则新文档会落在一个检索永远走不到的库里。
            Optional<String> aliasTarget = writeAliasTarget();
            if (aliasTarget.isPresent()) {
                String target = aliasTarget.get();
                boolean created = false;
                if (!client.exists("/" + target)) {
                    client.putJson("/" + target, mapping.createBody());
                    created = true;
                }
                activeIndex = target;
                ready = true;
                return new IndexState(created, false);
            }
            boolean created = false;
            if (!client.exists("/" + indexName())) {
                client.putJson("/" + indexName(), mapping.createBody());
                created = true;
            }
            boolean aliasSwitched = ensureAlias();
            ready = true;
            return new IndexState(created, aliasSwitched);
        }
    }

    /** 别名当前指向的写索引；别名不存在时返回 empty。 */
    private Optional<String> writeAliasTarget() {
        Optional<JsonObject> existing = client.findJson("/_alias/" + aliasName());
        if (existing.isEmpty()) {
            return Optional.empty();
        }
        JsonObject indices = existing.get();
        String first = null;
        for (String index : indices.keySet()) {
            if (first == null) {
                first = index;
            }
            JsonObject aliases = indices.getJsonObject(index);
            if (aliases == null) {
                continue;
            }
            jakarta.json.JsonValue metadata = aliases.get(aliasName());
            if (metadata == null || metadata.getValueType() != jakarta.json.JsonValue.ValueType.OBJECT) {
                continue;
            }
            if (metadata.asJsonObject().getBoolean("is_write_index", false)) {
                return Optional.of(index);
            }
        }
        return Optional.ofNullable(first);
    }

    /**
     * 迁移到指定索引。
     *
     * <p>目标索引不存在就按当前映射建出来，然后把写别名从旧索引挪过去。写入始终落在
     * 目标索引上，检索走别名，两边不会指向不同的库。
     */
    public MigrationResult migrateToNewIndex(String requestedIndexName) {
        String current = indexName();
        String target = requestedIndexName == null || requestedIndexName.isBlank()
                ? current + "_" + Instant.now().toEpochMilli()
                : requestedIndexName.trim();
        boolean created = false;
        if (!client.exists("/" + target)) {
            client.putJson("/" + target, mapping.createBody());
            created = true;
        }
        boolean aliasSwitched = switchAlias(target);
        activeIndex = target;
        ready = true;
        return new MigrationResult(created, aliasSwitched, target);
    }

    public boolean indexExists() {
        try {
            return client.exists("/" + indexName());
        } catch (ElasticsearchException error) {
            LOG.log(Level.WARNING, "Elasticsearch index probe failed for " + indexName(), error);
            return false;
        }
    }

    /** 写入分块文档；_id 使用 chunk id，重复写入即覆盖。 */
    public void indexChunk(String chunkId, JsonObject source) {
        ensureReady();
        client.putJson("/" + indexName() + "/_doc/" + chunkId, source);
    }

    /** 删除分块文档；索引不存在说明还没有向量，无需删除。 */
    public void deleteChunk(String chunkId) {
        if (chunkId == null || chunkId.isBlank()) {
            return;
        }
        if (!client.exists("/" + indexName())) {
            return;
        }
        client.deleteJson("/" + indexName() + "/_doc/" + chunkId);
    }

    private boolean ensureAlias() {
        Optional<JsonObject> existing = client.findJson("/_alias/" + aliasName());
        if (existing.isPresent()) {
            return false;
        }
        client.postJson("/_aliases", Json.createObjectBuilder()
                .add("actions", Json.createArrayBuilder()
                        .add(Json.createObjectBuilder()
                                .add("add", Json.createObjectBuilder()
                                        .add("index", indexName())
                                        .add("alias", aliasName())
                                        .add("is_write_index", true)
                                        .build())
                                .build())
                        .build())
                .build());
        return true;
    }

    /** 把写别名从所有旧索引挪到目标索引。 */
    private boolean switchAlias(String targetIndex) {
        jakarta.json.JsonArrayBuilder actions = Json.createArrayBuilder();
        client.findJson("/_alias/" + aliasName()).ifPresent(existing -> {
            for (String index : existing.keySet()) {
                if (index.equals(targetIndex)) {
                    continue;
                }
                actions.add(Json.createObjectBuilder()
                        .add("remove", Json.createObjectBuilder()
                                .add("index", index)
                                .add("alias", aliasName())
                                .build())
                        .build());
            }
        });
        actions.add(Json.createObjectBuilder()
                .add("add", Json.createObjectBuilder()
                        .add("index", targetIndex)
                        .add("alias", aliasName())
                        .add("is_write_index", true)
                        .build())
                .build());
        client.postJson("/_aliases", Json.createObjectBuilder()
                .add("actions", actions)
                .build());
        return true;
    }

    public String indexName() {
        String current = activeIndex;
        if (current == null || current.isBlank()) {
            current = properties.getIndexName();
            activeIndex = current;
        }
        return current;
    }

    public String aliasName() {
        return properties.getIndexAlias();
    }
}
