package com.tutict.finalassignmentbackend.rag.service;

import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.entity.offense.OffenseTypeDict;
import com.tutict.finalassignmentbackend.mapper.appeal.AppealRecordMapper;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseTypeDictMapper;
import com.tutict.finalassignmentbackend.rag.chunk.ChineseTextChunker;
import com.tutict.finalassignmentbackend.rag.chunk.Chunker;
import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import com.tutict.finalassignmentbackend.rag.dto.RagSourceDocument;
import com.tutict.finalassignmentbackend.rag.entity.RagChunk;
import com.tutict.finalassignmentbackend.rag.entity.RagDocument;
import com.tutict.finalassignmentbackend.rag.entity.RagEmbeddingTask;
import com.tutict.finalassignmentbackend.rag.indexing.RagBackfillJob;
import com.tutict.finalassignmentbackend.rag.ingestion.AppealRecordExtractor;
import com.tutict.finalassignmentbackend.rag.ingestion.OffenseTypeExtractor;
import com.tutict.finalassignmentbackend.rag.mapper.RagChunkMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagDocumentMapper;
import com.tutict.finalassignmentbackend.rag.mapper.RagEmbeddingTaskMapper;
import org.junit.jupiter.api.Test;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ChineseTextChunkerTest {

    @Test
    void chunksChineseTextWithOverlap() {
        ChineseTextChunker chunker = new ChineseTextChunker(5, 2);
        RagSourceDocument document = new RagSourceDocument(
                "BUSINESS",
                "table_a",
                "1",
                "v1",
                "title",
                "\u4e00\u4e8c\u4e09\u56db\u4e94\u516d\u4e03\u516b",
                "PUBLIC",
                "/route",
                "{}",
                "content"
        );

        List<Chunker.Chunk> chunks = chunker.chunk(document);

        assertThat(chunks).hasSize(2);
        assertThat(chunks.get(0).content()).isEqualTo("\u4e00\u4e8c\u4e09\u56db\u4e94");
        assertThat(chunks.get(1).content()).startsWith("\u56db\u4e94");
    }
}

class RagChunkHashTest {

    @Test
    void normalizedContentHashIsStable() {
        ChineseTextChunker chunker = new ChineseTextChunker(500, 100);

        String first = chunker.normalizedContentSha256(" abc\r\n\u4f60\u597d  ");
        String second = chunker.normalizedContentSha256("abc\n\u4f60\u597d");

        assertThat(first).isEqualTo(second);
        assertThat(first).hasSize(64);
    }
}

class RagDocumentLifecycleTest {

    @Test
    void indexesDocumentChunksAndEmbeddingTasksIdempotently() {
        InMemoryRagMappers mappers = new InMemoryRagMappers();
        RagIndexingService service = new RagIndexingService(
                new RagDocumentService(mappers.documentMapper),
                new RagChunkService(mappers.chunkMapper),
                new RagEmbeddingTaskService(mappers.taskMapper),
                new ChineseTextChunker(5, 1)
        );
        RagSourceDocument document = new RagSourceDocument(
                "BUSINESS",
                "offense_type_dict",
                "42",
                "v1",
                "title",
                "\u4e00\u4e8c\u4e09\u56db\u4e94\u516d",
                "ROLE",
                "/route",
                "{}",
                "description"
        );

        RagIndexingService.RagIndexingResult first = service.index(document);
        RagIndexingService.RagIndexingResult second = service.index(document);

        assertThat(first.chunks()).hasSize(2);
        assertThat(second.chunks()).hasSize(2);
        assertThat(mappers.documents).hasSize(1);
        assertThat(mappers.chunks).hasSize(2);
        assertThat(mappers.tasks).hasSize(2);
        assertThat(first.document().getAclScope()).isEqualTo("ROLE");
        assertThat(mappers.tasks.values()).extracting(RagEmbeddingTask::getStatus).containsOnly("PENDING");
    }
}

class RagBackfillJobTest {

    @Test
    void processesConfiguredBatchWithoutStartupSideEffects() {
        OffenseTypeDictMapper offenseMapper = mock(OffenseTypeDictMapper.class);
        AppealRecordMapper appealMapper = mock(AppealRecordMapper.class);
        RagIndexingService indexingService = mock(RagIndexingService.class);
        OffenseTypeDict offense = new OffenseTypeDict();
        offense.setTypeId(7);
        offense.setOffenseCode("A7");
        offense.setOffenseName("parking");
        offense.setUpdatedAt(LocalDateTime.parse("2026-01-01T00:00:00"));
        when(indexingService.index(any(RagSourceDocument.class))).thenReturn(null);
        when(offenseMapper.selectPage(any(Page.class), any(Wrapper.class))).thenAnswer(invocation -> {
            Page<OffenseTypeDict> page = invocation.getArgument(0);
            page.setRecords(List.of(offense));
            return page;
        });
        when(appealMapper.selectPage(any(Page.class), any(Wrapper.class))).thenAnswer(invocation -> {
            Page<AppealRecord> page = invocation.getArgument(0);
            page.setRecords(List.of());
            return page;
        });
        RagProperties properties = new RagProperties();
        properties.setEnabled(true);
        properties.getIndexing().setEnabled(true);
        properties.getIndexing().setBatchSize(1);
        RagBackfillJob job = new RagBackfillJob(
                offenseMapper,
                appealMapper,
                new OffenseTypeExtractor(new ObjectMapper()),
                new AppealRecordExtractor(new ObjectMapper()),
                indexingService,
                properties
        );

        RagBackfillJob.RagBackfillResult result = job.runNextBatch();

        assertThat(result.enabled()).isTrue();
        assertThat(result.processedDocuments()).isEqualTo(1);
        assertThat(result.failedDocuments()).isZero();
        assertThat(result.hasMore()).isTrue();
    }
}

final class InMemoryRagMappers {
    final Map<String, RagDocument> documents = new LinkedHashMap<>();
    final Map<String, RagChunk> chunks = new LinkedHashMap<>();
    final Map<String, RagEmbeddingTask> tasks = new LinkedHashMap<>();
    final RagDocumentMapper documentMapper = mock(RagDocumentMapper.class);
    final RagChunkMapper chunkMapper = mock(RagChunkMapper.class);
    final RagEmbeddingTaskMapper taskMapper = mock(RagEmbeddingTaskMapper.class);

    InMemoryRagMappers() {
        when(documentMapper.selectById(any(Serializable.class)))
                .thenAnswer(invocation -> documents.get(invocation.getArgument(0)));
        when(chunkMapper.selectById(any(Serializable.class)))
                .thenAnswer(invocation -> chunks.get(invocation.getArgument(0)));
        when(taskMapper.selectById(any(Serializable.class)))
                .thenAnswer(invocation -> tasks.get(invocation.getArgument(0)));
        when(documentMapper.insert(any(RagDocument.class))).thenAnswer(invocation -> {
            RagDocument document = invocation.getArgument(0);
            documents.put(document.getId(), document);
            return 1;
        });
        when(documentMapper.updateById(any(RagDocument.class))).thenAnswer(invocation -> {
            RagDocument document = invocation.getArgument(0);
            documents.put(document.getId(), document);
            return 1;
        });
        when(chunkMapper.insert(any(RagChunk.class))).thenAnswer(invocation -> {
            RagChunk chunk = invocation.getArgument(0);
            chunks.put(chunk.getId(), chunk);
            return 1;
        });
        when(chunkMapper.updateById(any(RagChunk.class))).thenAnswer(invocation -> {
            RagChunk chunk = invocation.getArgument(0);
            chunks.put(chunk.getId(), chunk);
            return 1;
        });
        when(taskMapper.insert(any(RagEmbeddingTask.class))).thenAnswer(invocation -> {
            RagEmbeddingTask task = invocation.getArgument(0);
            tasks.put(task.getId(), task);
            return 1;
        });
        when(taskMapper.updateById(any(RagEmbeddingTask.class))).thenAnswer(invocation -> {
            RagEmbeddingTask task = invocation.getArgument(0);
            tasks.put(task.getId(), task);
            return 1;
        });
    }
}
