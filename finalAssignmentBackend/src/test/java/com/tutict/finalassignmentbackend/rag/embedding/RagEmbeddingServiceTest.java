package com.tutict.finalassignmentbackend.rag.embedding;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.tutict.finalassignmentbackend.ai.rag.config.RagChunkIndexMapping;
import com.tutict.finalassignmentbackend.ai.rag.retrieval.EmbeddingProvider;
import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import com.tutict.finalassignmentbackend.rag.entity.RagChunk;
import com.tutict.finalassignmentbackend.rag.entity.RagDocument;
import com.tutict.finalassignmentbackend.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentbackend.rag.indexing.RagIndexMaintenanceService;
import com.tutict.finalassignmentbackend.rag.mapper.RagChunkMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagDocumentMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagEmbeddingTaskMapper;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RagEmbeddingServiceTest {

    private static final String CHUNK_CONTENT = "traffic appeal source material";

    @Test
    void embedsPendingChunkIndexesVectorAndMarksTaskSucceeded() {
        RagEmbeddingTaskMapper taskMapper = mock(RagEmbeddingTaskMapper.class);
        RagChunkMapper chunkMapper = mock(RagChunkMapper.class);
        RagDocumentMapper documentMapper = mock(RagDocumentMapper.class);
        EmbeddingProvider embeddingProvider = mock(EmbeddingProvider.class);
        RagChunkVectorIndexService vectorIndexService = mock(RagChunkVectorIndexService.class);
        RagProperties properties = new RagProperties();
        properties.setEnabled(true);
        properties.getEmbedding().setEnabled(true);
        properties.getEmbedding().setDimensions(3);

        RagEmbeddingTask task = task();
        RagChunk chunk = chunk();
        RagDocument document = document();
        when(taskMapper.selectList(any(QueryWrapper.class))).thenReturn(List.of(task));
        when(taskMapper.selectById(any(Serializable.class))).thenReturn(task);
        when(chunkMapper.selectById(any(Serializable.class))).thenReturn(chunk);
        when(documentMapper.selectById(any(Serializable.class))).thenReturn(document);
        when(embeddingProvider.providerName()).thenReturn("test");
        when(embeddingProvider.modelName()).thenReturn("test-embed");
        when(embeddingProvider.embed(CHUNK_CONTENT)).thenReturn(new float[] {1, 0, 0});

        RagEmbeddingService service = new RagEmbeddingService(
                taskMapper,
                chunkMapper,
                documentMapper,
                embeddingProvider,
                vectorIndexService,
                properties
        );

        RagEmbeddingService.RagEmbeddingBatchResult result = service.processPendingBatch(10);

        assertThat(result.selectedTasks()).isEqualTo(1);
        assertThat(result.succeededTasks()).isEqualTo(1);
        ArgumentCaptor<float[]> vectorCaptor = ArgumentCaptor.forClass(float[].class);
        verify(vectorIndexService).index(eq(document), eq(chunk), vectorCaptor.capture(), eq("test"), eq("test-embed"));
        assertThat(vectorCaptor.getValue()).containsExactly(1.0f, 0.0f, 0.0f);

        ArgumentCaptor<RagChunk> chunkCaptor = ArgumentCaptor.forClass(RagChunk.class);
        verify(chunkMapper).updateById(chunkCaptor.capture());
        assertThat(chunkCaptor.getValue().getStatus()).isEqualTo("EMBEDDED");
        assertThat(chunkCaptor.getValue().getEmbeddingModel()).isEqualTo("test-embed");
        assertThat(chunkCaptor.getValue().getEmbeddingHash()).hasSize(64);

        ArgumentCaptor<RagEmbeddingTask> taskCaptor = ArgumentCaptor.forClass(RagEmbeddingTask.class);
        verify(taskMapper, atLeastOnce()).updateById(taskCaptor.capture());
        assertThat(taskCaptor.getAllValues().get(taskCaptor.getAllValues().size() - 1).getStatus()).isEqualTo("SUCCEEDED");
    }

    @Test
    void requeuesExistingChunksAndCreatesMissingEmbeddingTask() {
        RagChunkMapper chunkMapper = mock(RagChunkMapper.class);
        RagEmbeddingTaskMapper taskMapper = mock(RagEmbeddingTaskMapper.class);
        ObjectProvider<ElasticsearchOperations> operationsProvider = mock(ObjectProvider.class);
        RagProperties properties = new RagProperties();
        properties.getEmbedding().setProvider("test");
        properties.getEmbedding().setModel("test-embed");
        RagChunk chunk = chunk();
        when(chunkMapper.selectList(any(QueryWrapper.class))).thenReturn(List.of(chunk));
        when(chunkMapper.update(isNull(), any(UpdateWrapper.class))).thenReturn(1);
        when(taskMapper.update(isNull(), any(UpdateWrapper.class))).thenReturn(0);

        RagIndexMaintenanceService service = new RagIndexMaintenanceService(
                operationsProvider,
                new RagChunkIndexMapping(properties),
                chunkMapper,
                taskMapper,
                properties
        );

        RagIndexMaintenanceService.RequeueResult result = service.requeueEmbeddingTasks(10);

        assertThat(result.requeuedChunks()).isEqualTo(1);
        assertThat(result.requeuedTasks()).isZero();
        assertThat(result.createdTasks()).isEqualTo(1);
        ArgumentCaptor<RagEmbeddingTask> taskCaptor = ArgumentCaptor.forClass(RagEmbeddingTask.class);
        verify(taskMapper).insert(taskCaptor.capture());
        assertThat(taskCaptor.getValue().getChunkId()).isEqualTo("chunk-1");
        assertThat(taskCaptor.getValue().getProvider()).isEqualTo("test");
        assertThat(taskCaptor.getValue().getModel()).isEqualTo("test-embed");
        assertThat(taskCaptor.getValue().getStatus()).isEqualTo("PENDING");
    }

    private static RagEmbeddingTask task() {
        RagEmbeddingTask task = new RagEmbeddingTask();
        task.setId("task-1");
        task.setChunkId("chunk-1");
        task.setTaskKey("task-1");
        task.setProvider("test");
        task.setModel("test-embed");
        task.setStatus("PENDING");
        task.setAttemptCount(0);
        task.setCreatedAt(LocalDateTime.now());
        task.setUpdatedAt(LocalDateTime.now());
        return task;
    }

    private static RagChunk chunk() {
        RagChunk chunk = new RagChunk();
        chunk.setId("chunk-1");
        chunk.setDocumentId("doc-1");
        chunk.setContent(CHUNK_CONTENT);
        chunk.setContentHash("hash");
        chunk.setSourceField("content");
        chunk.setStatus("PENDING_EMBEDDING");
        return chunk;
    }

    private static RagDocument document() {
        RagDocument document = new RagDocument();
        document.setId("doc-1");
        document.setTitle("Appeal material");
        document.setSourceType("MANUAL");
        document.setSourceTable("manual_rag_document");
        document.setSourceId("manual-1");
        document.setSourceVersion("v1");
        document.setAclScope("PUBLIC");
        document.setRoute("");
        document.setMetadataJson("{}");
        return document;
    }
}
