package com.tutict.finalassignmentbackend.rag.chunk;

import com.tutict.finalassignmentbackend.rag.dto.RagSourceDocument;

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
