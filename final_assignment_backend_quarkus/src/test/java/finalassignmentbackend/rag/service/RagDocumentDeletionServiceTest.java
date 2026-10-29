package finalassignmentbackend.rag.service;

import finalassignmentbackend.mapper.RagChunkMapper;
import finalassignmentbackend.mapper.RagDocumentMapper;
import finalassignmentbackend.mapper.RagEmbeddingTaskMapper;
import finalassignmentbackend.rag.elasticsearch.RagIndexManager;
import finalassignmentbackend.rag.entity.RagChunk;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RagDocumentDeletionServiceTest {

    private RagDocumentDeletionService service;
    private FakeIndexManager indexManager;
    private List<RagChunk> chunks;
    private int deletedTasks;
    private int deletedChunks;
    private int deletedDocuments;

    @BeforeEach
    void setUp() {
        chunks = new ArrayList<>();
        deletedTasks = 0;
        deletedChunks = 0;
        deletedDocuments = 0;
        indexManager = new FakeIndexManager();
        service = new RagDocumentDeletionService();
        service.documentMapper = documentMapper();
        service.chunkMapper = chunkMapper();
        service.taskMapper = taskMapper();
        service.indexManager = indexManager;
    }

    @Test
    void deletingRemovesTasksChunksAndDocument() {
        chunks.add(chunk("chunk-1"));
        chunks.add(chunk("chunk-2"));

        RagDocumentDeletionService.DeletionResult result = service.delete("doc-1");

        assertEquals(1, result.documents());
        assertEquals(2, result.chunks());
        assertEquals(3, result.tasks());
    }

    @Test
    void deletingRemovesTheIndexedVectorsOfEveryChunk() {
        chunks.add(chunk("chunk-1"));
        chunks.add(chunk("chunk-2"));

        service.delete("doc-1");

        assertEquals(List.of("chunk-1", "chunk-2"), indexManager.deleted);
    }

    @Test
    void elasticsearchFailureDoesNotUndoTheDatabaseDeletion() {
        chunks.add(chunk("chunk-1"));
        indexManager.failure = new IllegalStateException("elasticsearch unreachable");

        RagDocumentDeletionService.DeletionResult result = service.delete("doc-1");

        assertEquals(1, result.documents());
        assertEquals(1, result.chunks());
    }

    @Test
    void deletingWithoutChunksIsStillReported() {
        RagDocumentDeletionService.DeletionResult result = service.delete("doc-1");

        assertEquals(1, result.documents());
        assertEquals(0, result.chunks());
        assertEquals(0, result.tasks());
        assertTrue(indexManager.deleted.isEmpty());
    }

    private static RagChunk chunk(String id) {
        RagChunk chunk = new RagChunk();
        chunk.setId(id);
        chunk.setDocumentId("doc-1");
        chunk.setStatus("EMBEDDED");
        return chunk;
    }

    private RagDocumentMapper documentMapper() {
        return (RagDocumentMapper) Proxy.newProxyInstance(
                RagDocumentMapper.class.getClassLoader(),
                new Class<?>[]{RagDocumentMapper.class},
                (proxy, method, args) -> {
                    if ("deleteById".equals(method.getName())) {
                        deletedDocuments = 1;
                        return 1;
                    }
                    return null;
                });
    }

    private RagChunkMapper chunkMapper() {
        return (RagChunkMapper) Proxy.newProxyInstance(
                RagChunkMapper.class.getClassLoader(),
                new Class<?>[]{RagChunkMapper.class},
                (proxy, method, args) -> {
                    if ("selectList".equals(method.getName())) {
                        return chunks;
                    }
                    if ("delete".equals(method.getName())) {
                        deletedChunks = chunks.size();
                        return deletedChunks;
                    }
                    return null;
                });
    }

    private RagEmbeddingTaskMapper taskMapper() {
        return (RagEmbeddingTaskMapper) Proxy.newProxyInstance(
                RagEmbeddingTaskMapper.class.getClassLoader(),
                new Class<?>[]{RagEmbeddingTaskMapper.class},
                (proxy, method, args) -> {
                    if ("delete".equals(method.getName())) {
                        deletedTasks = 3;
                        return deletedTasks;
                    }
                    return null;
                });
    }

    private static final class FakeIndexManager extends RagIndexManager {

        private final List<String> deleted = new ArrayList<>();
        private RuntimeException failure;

        @Override
        public void deleteChunk(String chunkId) {
            if (failure != null) {
                throw failure;
            }
            deleted.add(chunkId);
        }
    }
}
