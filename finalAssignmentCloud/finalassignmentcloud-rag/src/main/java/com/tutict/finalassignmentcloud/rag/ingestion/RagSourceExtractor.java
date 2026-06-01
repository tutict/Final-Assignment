package com.tutict.finalassignmentcloud.rag.ingestion;

import com.tutict.finalassignmentcloud.rag.dto.RagSourceDocument;

public interface RagSourceExtractor<T> {

    String sourceTable();

    RagSourceDocument extract(T source);
}

