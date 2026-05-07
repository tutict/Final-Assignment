package com.tutict.finalassignmentbackend.rag.ingestion;

import com.tutict.finalassignmentbackend.rag.dto.RagSourceDocument;

public interface RagSourceExtractor<T> {

    String sourceTable();

    RagSourceDocument extract(T source);
}
