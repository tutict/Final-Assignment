CREATE TABLE IF NOT EXISTS rag_document (
    id VARCHAR(64) PRIMARY KEY,
    source_type VARCHAR(64) NOT NULL,
    source_table VARCHAR(128) NOT NULL,
    source_id VARCHAR(128) NOT NULL,
    source_version VARCHAR(128) NOT NULL,
    title VARCHAR(512) NOT NULL,
    content_hash CHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL,
    acl_scope VARCHAR(32) NOT NULL,
    route VARCHAR(512) NULL,
    metadata_json JSON NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    indexed_at DATETIME NULL,
    UNIQUE KEY uk_rag_document_source (source_table, source_id, source_version),
    KEY idx_rag_document_status (status),
    KEY idx_rag_document_acl_scope (acl_scope)
);

CREATE TABLE IF NOT EXISTS rag_chunk (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL,
    chunk_no INT NOT NULL,
    content TEXT NOT NULL,
    content_hash CHAR(64) NOT NULL,
    token_count INT NOT NULL,
    char_count INT NOT NULL,
    source_field VARCHAR(128) NOT NULL,
    status VARCHAR(32) NOT NULL,
    embedding_model VARCHAR(128) NULL,
    embedding_hash CHAR(64) NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE KEY uk_rag_chunk_document_no_hash (document_id, chunk_no, content_hash),
    KEY idx_rag_chunk_document_id (document_id),
    KEY idx_rag_chunk_status (status),
    CONSTRAINT fk_rag_chunk_document FOREIGN KEY (document_id) REFERENCES rag_document (id)
);

CREATE TABLE IF NOT EXISTS rag_embedding_task (
    id VARCHAR(64) PRIMARY KEY,
    chunk_id VARCHAR(64) NOT NULL,
    task_key VARCHAR(128) NOT NULL,
    provider VARCHAR(64) NOT NULL,
    model VARCHAR(128) NOT NULL,
    status VARCHAR(32) NOT NULL,
    attempt_count INT NOT NULL DEFAULT 0,
    next_retry_at DATETIME NULL,
    last_error TEXT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE KEY uk_rag_embedding_task_key (task_key),
    KEY idx_rag_embedding_task_status_retry (status, next_retry_at),
    KEY idx_rag_embedding_task_chunk_id (chunk_id),
    CONSTRAINT fk_rag_embedding_task_chunk FOREIGN KEY (chunk_id) REFERENCES rag_chunk (id)
);
