package com.tutict.finalassignmentcloud.rag.embedding;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.rag.ai.config.RagChunkIndexMapping;
import com.tutict.finalassignmentcloud.rag.entity.RagChunk;
import com.tutict.finalassignmentcloud.rag.entity.RagDocument;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.elasticsearch.ResourceNotFoundException;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.IndexOperations;
import org.springframework.data.elasticsearch.core.index.AliasActions;
import org.springframework.data.elasticsearch.core.mapping.IndexCoordinates;
import org.springframework.data.elasticsearch.core.query.IndexQuery;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
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
        when(mapping.aliasName()).thenReturn("rag_chunk_cloud_current");
        when(mapping.indexName()).thenReturn("rag_chunk_cloud_v1");

        IndexOperations indexOperations = mock(IndexOperations.class);
        when(operations.indexOps(any(IndexCoordinates.class))).thenReturn(indexOperations);
        when(indexOperations.exists()).thenReturn(true);
        when(indexOperations.getAliases(any(String[].class)))
                .thenThrow(new ResourceNotFoundException("alias [rag_chunk_cloud_current] missing"));

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
}
