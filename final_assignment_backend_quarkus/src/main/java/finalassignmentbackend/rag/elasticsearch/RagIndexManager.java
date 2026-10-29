package finalassignmentbackend.rag.elasticsearch;

import finalassignmentbackend.rag.config.RagProperties;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.json.JsonObject;

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

    /** 幂等地确保索引与别名存在。 */
    public IndexState ensureReady() {
        if (ready) {
            return new IndexState(false, false);
        }
        synchronized (this) {
            if (ready) {
                return new IndexState(false, false);
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

    /** 删除分块文档；文档不存在视为成功。 */
    public void deleteChunk(String chunkId) {
        ensureReady();
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

    public String indexName() {
        return properties.getIndexName();
    }

    public String aliasName() {
        return properties.getIndexAlias();
    }
}
