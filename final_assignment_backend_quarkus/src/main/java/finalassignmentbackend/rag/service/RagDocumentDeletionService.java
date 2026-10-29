package finalassignmentbackend.rag.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.mapper.RagEmbeddingTaskMapper;
import finalassignmentbackend.offense.governance.AfterCommitBoundary;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 删除知识库文档。
 *
 * <p>库里的删除是权威动作，必须一次事务完成：任务、分块、文档要么全删要么全留。
 * ES 里的向量文档在事务提交后才删——提前删会让事务回滚后索引出现空洞。
 * ES 删除失败只记日志：索引里的残留不会阻碍删除，检索侧回读 MySQL 时也会把它过滤掉。
 */
@ApplicationScoped
public class RagDocumentDeletionService {

    private static final Logger LOG = Logger.getLogger(RagDocumentDeletionService.class.getName());

    @Inject RagDocumentMapper documentMapper;
    @Inject RagChunkMapper chunkMapper;
    @Inject RagEmbeddingTaskMapper taskMapper;
    @Inject RagIndexManager indexManager;

    public record DeletionResult(int documents, int chunks, int tasks) {
    }

    @Transactional
    public DeletionResult delete(String documentId) {
        List<RagChunk> chunks = chunkMapper.selectList(
                new QueryWrapper<RagChunk>().eq("document_id", documentId)
        );
        List<String> chunkIds = new ArrayList<>();
        for (RagChunk chunk : chunks) {
            if (chunk.getId() != null && !chunk.getId().isBlank()) {
                chunkIds.add(chunk.getId());
            }
        }
        int deletedTasks = chunkIds.isEmpty()
                ? 0
                : taskMapper.delete(new QueryWrapper<RagEmbeddingTask>().in("chunk_id", chunkIds));
        int deletedChunks = chunkMapper.delete(new QueryWrapper<RagChunk>().eq("document_id", documentId));
        int deletedDocuments = documentMapper.deleteById(documentId);
        new AfterCommitBoundary().afterCommit(() -> removeFromIndex(chunkIds));
        return new DeletionResult(deletedDocuments, deletedChunks, deletedTasks);
    }

    private void removeFromIndex(List<String> chunkIds) {
        for (String chunkId : chunkIds) {
            try {
                indexManager.deleteChunk(chunkId);
            } catch (RuntimeException error) {
                LOG.log(Level.WARNING, "Failed to delete RAG chunk from Elasticsearch: " + chunkId, error);
            }
        }
    }
}
