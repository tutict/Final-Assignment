package com.tutict.finalassignmentbackend.rag.embedding;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.rag.config.RagChunkIndexMapping;
import com.tutict.finalassignmentbackend.rag.entity.RagChunk;
import com.tutict.finalassignmentbackend.rag.entity.RagDocument;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.elasticsearch.ResourceNotFoundException;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.IndexOperations;
import org.springframework.data.elasticsearch.core.index.AliasActions;
import org.springframework.data.elasticsearch.core.mapping.IndexCoordinates;
import org.springframework.data.elasticsearch.core.query.DeleteQuery;
import org.springframework.data.elasticsearch.core.query.IndexQuery;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RagChunkVectorIndexServiceTest {

    @Test
    void indexCreatesAliasWhenLookupReportsMissingAlias() {
        ElasticsearchOperations operations = mock(ElasticsearchOperations.class);
        @SuppressWarnings("unchecked")
        ObjectProvider<ElasticsearchOperations> provider = mock(ObjectProvider.class);
        when(provider.getIfAvailable()).thenReturn(operations);

        RagChunkIndexMapping mapping = mock(RagChunkIndexMapping.class);
        when(mapping.aliasName()).thenReturn("rag-chunks");
        when(mapping.indexName()).thenReturn("rag-chunks-v1");

        IndexOperations indexOperations = mock(IndexOperations.class);
        when(operations.indexOps(any(IndexCoordinates.class))).thenReturn(indexOperations);
        when(indexOperations.exists()).thenReturn(true);
        when(indexOperations.getAliases(any(String[].class)))
                .thenThrow(new ResourceNotFoundException("alias [rag-chunks] missing"));

        RagChunkVectorIndexService service = new RagChunkVectorIndexService(
                provider,
                mapping,
                new ObjectMapper()
        );

        RagDocument document = new RagDocument();
        document.setId("doc-1");
        document.setTitle("Load dataset");
        RagChunk chunk = new RagChunk();
        chunk.setId("chunk-1");
        chunk.setDocumentId("doc-1");
        chunk.setContent("交通违法申诉办理指南");

        service.index(document, chunk, new float[]{0.1f, 0.2f}, "ollama", "nomic-embed-text");

        verify(indexOperations).alias(any(AliasActions.class));
        verify(operations).index(any(IndexQuery.class), any(IndexCoordinates.class));
    }

    @Test
    void deleteByDocumentIdUsesDeleteQueryInsteadOfDocumentId() {
        ElasticsearchOperations operations = mock(ElasticsearchOperations.class);
        @SuppressWarnings("unchecked")
        ObjectProvider<ElasticsearchOperations> provider = mock(ObjectProvider.class);
        when(provider.getIfAvailable()).thenReturn(operations);

        RagChunkIndexMapping mapping = mock(RagChunkIndexMapping.class);
        when(mapping.aliasName()).thenReturn("rag-chunks");
        when(mapping.indexName()).thenReturn("rag-chunks-v1");

        RagChunkVectorIndexService service = new RagChunkVectorIndexService(
                provider,
                mapping,
                new ObjectMapper()
        );
        service.deleteByDocumentId("doc-1");

        ArgumentCaptor<DeleteQuery> captor = ArgumentCaptor.forClass(DeleteQuery.class);
        verify(operations).delete(captor.capture(), eq(Map.class), any(IndexCoordinates.class));
        assertThat(captor.getValue().getQuery()).isNotNull();
        verify(operations, never()).delete(anyString(), any(IndexCoordinates.class));
    }
}
