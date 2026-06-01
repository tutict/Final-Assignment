package com.tutict.finalassignmentcloud.rag.indexing;

import com.tutict.finalassignmentcloud.rag.config.RagProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@ConditionalOnProperty(prefix = "rag.backfill", name = "enabled", havingValue = "true")
public class RagBackfillJob {

    private final RagProperties properties;

    public RagBackfillJob(RagProperties properties) {
        this.properties = properties;
    }

    public RagBackfillResult runBatch(int page, int size) {
        return new RagBackfillResult(
                page,
                size,
                0,
                0,
                !properties.isEnabled(),
                List.of("Cloud RAG backfill is a service boundary. Business services must publish source documents or expose provider APIs before batch backfill can run.")
        );
    }

    public RagBackfillRunResult runBatches(int startPage, int size, int maxPages) {
        int safePages = Math.max(1, maxPages);
        List<RagBackfillResult> batches = new ArrayList<>();
        for (int i = 0; i < safePages; i++) {
            batches.add(runBatch(startPage + i, size));
        }
        return new RagBackfillRunResult(startPage, size, safePages, 0, 0, List.copyOf(batches));
    }

    public record RagBackfillResult(
            int page,
            int size,
            int sourceDocumentCount,
            int indexedDocumentCount,
            boolean disabled,
            List<String> notes
    ) {
    }

    public record RagBackfillRunResult(
            int startPage,
            int size,
            int requestedPages,
            int sourceDocumentCount,
            int indexedDocumentCount,
            List<RagBackfillResult> batches
    ) {
    }
}
