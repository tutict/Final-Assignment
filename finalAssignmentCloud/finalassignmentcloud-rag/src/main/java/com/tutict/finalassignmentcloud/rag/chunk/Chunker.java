package com.tutict.finalassignmentcloud.rag.chunk;

import com.tutict.finalassignmentcloud.rag.dto.RagSourceDocument;

import java.util.List;

public interface Chunker {

    List<Chunk> chunk(RagSourceDocument document);

    String normalizedContentSha256(String content);

    record Chunk(
            int chunkNo,
            String content,
            String contentHash,
            int tokenCount,
            int charCount,
            String sourceField
    ) {
    }
}

