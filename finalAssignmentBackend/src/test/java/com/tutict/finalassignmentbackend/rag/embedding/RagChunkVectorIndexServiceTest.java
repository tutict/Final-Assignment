package com.tutict.finalassignmentbackend.rag.embedding;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.rag.config.RagChunkIndexMapping;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.mapping.IndexCoordinates;
import org.springframework.data.elasticsearch.core.query.DeleteQuery;

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
