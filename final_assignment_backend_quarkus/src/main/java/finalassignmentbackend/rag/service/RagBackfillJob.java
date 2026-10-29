package finalassignmentbackend.rag.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.rag.config.RagProperties;
import finalassignmentbackend.rag.embedding.RagEmbeddingProvider;
import finalassignmentbackend.rag.embedding.RagEmbeddingStatus;
import finalassignmentbackend.rag.embedding.RagEmbeddingTaskStore;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagDocument;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.util.List;

/**
 * 知识库回填。
 *
 * <p>把知识文档的分块重新对齐到嵌入队列：还没嵌入的分块退回待嵌入状态，并保证队列里
 * 有一条对应的待处理任务。已经嵌入好的分块不动，因此回填可以反复执行。
 *
 * <p>与 Spring 的差异：Spring 的回填是把业务表（违法类型、申诉记录）重新灌进索引，
 * Quarkus 侧没有对应的抽取器，这里改为保证已有知识文档的向量是齐的。
 */
@ApplicationScoped
public class RagBackfillJob {

    private static final int MAX_BATCH_SIZE = 200;
    private static final int MAX_PAGES = 50;

    @Inject RagDocumentMapper documentMapper;
    @Inject RagChunkMapper chunkMapper;
    @Inject RagEmbeddingTaskStore store;
    @Inject RagEmbeddingProvider provider;
    @Inject RagProperties properties;

    public record RagBackfillResult(int processedDocuments, int failedDocuments, boolean hasMore, boolean enabled) {
    }

    public record RagBackfillRunResult(
            int processedDocuments,
            int failedDocuments,
            int processedPages,
            boolean hasMore,
            boolean enabled
    ) {
    }

    public RagBackfillResult runBatch(int page, int size) {
        if (!properties.isEnabled() || !properties.isIndexingEnabled()) {
            return new RagBackfillResult(0, 0, false, false);
        }
        int effectivePage = Math.max(1, page);
        int effectiveSize = Math.max(1, Math.min(size, MAX_BATCH_SIZE));
        Page<RagDocument> documents = documentMapper.selectPage(
                new Page<>(effectivePage, effectiveSize),
                new QueryWrapper<RagDocument>().in("source_type", List.of("MANUAL", "UPLOAD"))
        );
        List<RagDocument> records = documents.getRecords();
        int processed = 0;
        int failed = 0;
        for (RagDocument document : records) {
            try {
                backfillDocument(document);
                processed++;
            } catch (RuntimeException error) {
                failed++;
            }
        }
        return new RagBackfillResult(processed, failed, records.size() >= effectiveSize, true);
    }

    public RagBackfillRunResult runBatches(int startPage, int size, int maxPages) {
        if (!properties.isEnabled() || !properties.isIndexingEnabled()) {
            return new RagBackfillRunResult(0, 0, 0, false, false);
        }
        int effectiveStartPage = Math.max(1, startPage);
        int effectiveMaxPages = Math.min(Math.max(1, maxPages), MAX_PAGES);
        int processed = 0;
        int failed = 0;
        int pages = 0;
        boolean hasMore = false;
        for (int offset = 0; offset < effectiveMaxPages; offset++) {
            RagBackfillResult result = runBatch(effectiveStartPage + offset, size);
            pages++;
            processed += result.processedDocuments();
            failed += result.failedDocuments();
            hasMore = result.hasMore();
            if (!hasMore) {
                break;
            }
        }
        return new RagBackfillRunResult(processed, failed, pages, hasMore, true);
    }

    /** 让文档下所有未嵌入的分块重新排队。 */
    private void backfillDocument(RagDocument document) {
        if (document == null || document.getId() == null) {
            return;
        }
        List<RagChunk> chunks = chunkMapper.selectList(
                new QueryWrapper<RagChunk>().eq("document_id", document.getId())
        );
        for (RagChunk chunk : chunks) {
            if (RagEmbeddingStatus.CHUNK_EMBEDDED.equals(chunk.getStatus())) {
                continue;
            }
            store.resetChunk(chunk, provider.modelName());
            if (store.resetTasks(chunk.getId(), provider.providerName(), provider.modelName()) == 0) {
                store.createPendingTask(chunk.getId(), provider.providerName(), provider.modelName());
            }
        }
    }
}
