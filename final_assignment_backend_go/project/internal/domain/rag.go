package domain

import "time"

const (
	RagDocumentStatusReady = "READY"

	RagChunkStatusPendingEmbedding = "PENDING_EMBEDDING"
	RagChunkStatusEmbedded         = "EMBEDDED"

	RagEmbeddingTaskStatusPending   = "PENDING"
	RagEmbeddingTaskStatusRunning   = "RUNNING"
	RagEmbeddingTaskStatusSucceeded = "SUCCEEDED"
	RagEmbeddingTaskStatusFailed    = "FAILED"
	RagEmbeddingTaskStatusPoisoned  = "POISONED"
)

type RagDocument struct {
	ID            string     `gorm:"column:id;primaryKey" json:"id"`
	SourceType    string     `gorm:"column:source_type" json:"sourceType"`
	SourceTable   string     `gorm:"column:source_table" json:"sourceTable"`
	SourceID      string     `gorm:"column:source_id" json:"sourceId"`
	SourceVersion string     `gorm:"column:source_version" json:"sourceVersion"`
	Title         string     `gorm:"column:title" json:"title"`
	ContentHash   string     `gorm:"column:content_hash" json:"contentHash"`
	Status        string     `gorm:"column:status" json:"status"`
	ACLScope      string     `gorm:"column:acl_scope" json:"aclScope"`
	Route         string     `gorm:"column:route" json:"route"`
	MetadataJSON  string     `gorm:"column:metadata_json" json:"metadataJson"`
	CreatedAt     time.Time  `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt     time.Time  `gorm:"column:updated_at" json:"updatedAt"`
	IndexedAt     *time.Time `gorm:"column:indexed_at" json:"indexedAt,omitempty"`
}

func (RagDocument) TableName() string {
	return "rag_document"
}

type RagChunk struct {
	ID             string    `gorm:"column:id;primaryKey" json:"id"`
	DocumentID     string    `gorm:"column:document_id" json:"documentId"`
	ChunkNo        int       `gorm:"column:chunk_no" json:"chunkNo"`
	Content        string    `gorm:"column:content" json:"content"`
	ContentHash    string    `gorm:"column:content_hash" json:"contentHash"`
	TokenCount     int       `gorm:"column:token_count" json:"tokenCount"`
	CharCount      int       `gorm:"column:char_count" json:"charCount"`
	SourceField    string    `gorm:"column:source_field" json:"sourceField"`
	Status         string    `gorm:"column:status" json:"status"`
	EmbeddingModel string    `gorm:"column:embedding_model" json:"embeddingModel"`
	EmbeddingHash  string    `gorm:"column:embedding_hash" json:"embeddingHash"`
	CreatedAt      time.Time `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt      time.Time `gorm:"column:updated_at" json:"updatedAt"`
}

func (RagChunk) TableName() string {
	return "rag_chunk"
}

type RagEmbeddingTask struct {
	ID           string     `gorm:"column:id;primaryKey" json:"id"`
	ChunkID      string     `gorm:"column:chunk_id" json:"chunkId"`
	TaskKey      string     `gorm:"column:task_key" json:"taskKey"`
	Provider     string     `gorm:"column:provider" json:"provider"`
	Model        string     `gorm:"column:model" json:"model"`
	Status       string     `gorm:"column:status" json:"status"`
	AttemptCount int        `gorm:"column:attempt_count" json:"attemptCount"`
	NextRetryAt  *time.Time `gorm:"column:next_retry_at" json:"nextRetryAt,omitempty"`
	LastError    string     `gorm:"column:last_error" json:"lastError"`
	CreatedAt    time.Time  `gorm:"column:created_at" json:"createdAt"`
	UpdatedAt    time.Time  `gorm:"column:updated_at" json:"updatedAt"`
}

func (RagEmbeddingTask) TableName() string {
	return "rag_embedding_task"
}

type RagSourceDocument struct {
	SourceType    string `json:"sourceType"`
	SourceTable   string `json:"sourceTable"`
	SourceID      string `json:"sourceId"`
	SourceVersion string `json:"sourceVersion"`
	Title         string `json:"title"`
	Content       string `json:"content"`
	ACLScope      string `json:"aclScope"`
	Route         string `json:"route"`
	MetadataJSON  string `json:"metadataJson"`
	SourceField   string `json:"sourceField"`
}
