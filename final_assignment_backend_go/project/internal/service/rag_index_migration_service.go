package service

import (
	"context"
	"fmt"
	"strings"
	"time"
)

type RagIndexMigrationService struct {
	indexManager *RagIndexManagerService
	tasks        *RagEmbeddingTaskService
	config       RagConfig
}

func NewRagIndexMigrationService(
	indexManager *RagIndexManagerService,
	tasks *RagEmbeddingTaskService,
	config RagConfig,
) *RagIndexMigrationService {
	return &RagIndexMigrationService{
		indexManager: indexManager,
		tasks:        tasks,
		config:       normalizeRagConfig(config),
	}
}

func (s *RagIndexMigrationService) MigrateToNewIndex(
	ctx context.Context,
	requestedIndexName string,
	requeue bool,
	requeueLimit int,
) (RagIndexMigrationResult, error) {
	if !s.config.Enabled {
		return RagIndexMigrationResult{Enabled: false, Message: "RAG is disabled"}, nil
	}

	targetIndexName := strings.TrimSpace(requestedIndexName)
	if targetIndexName == "" {
		targetIndexName = s.indexManager.DefaultIndexName()
	}
	created, err := s.indexManager.CreateIndex(ctx, targetIndexName)
	if err != nil {
		return RagIndexMigrationResult{}, err
	}
	aliasSwitched, err := s.indexManager.SwitchWriteAlias(ctx, targetIndexName)
	if err != nil {
		return RagIndexMigrationResult{}, err
	}

	var requeueResult RagRequeueResult
	if requeue {
		requeueResult, err = s.tasks.RequeueChunks(ctx, requeueLimit, time.Now().UTC())
		if err != nil {
			return RagIndexMigrationResult{}, err
		}
	}

	return RagIndexMigrationResult{
		Enabled:         true,
		CreatedIndex:    created,
		AliasSwitched:   aliasSwitched,
		TargetIndexName: targetIndexName,
		AliasName:       s.indexManager.AliasName(),
		RequeuedChunks:  requeueResult.RequeuedChunks,
		RequeuedTasks:   requeueResult.RequeuedTasks,
		CreatedTasks:    requeueResult.CreatedTasks,
	}, nil
}

type RagIndexManagerService struct {
	manager RagVectorIndexManager
}

func NewRagIndexManagerService(manager RagVectorIndexManager) *RagIndexManagerService {
	return &RagIndexManagerService{manager: manager}
}

func (s *RagIndexManagerService) CreateIndex(ctx context.Context, indexName string) (bool, error) {
	if s == nil || s.manager == nil {
		return false, fmt.Errorf("rag vector index manager is not configured")
	}
	return s.manager.CreateIndex(ctx, indexName)
}

func (s *RagIndexManagerService) SwitchWriteAlias(ctx context.Context, indexName string) (bool, error) {
	if s == nil || s.manager == nil {
		return false, fmt.Errorf("rag vector index manager is not configured")
	}
	return s.manager.SwitchWriteAlias(ctx, indexName)
}

func (s *RagIndexManagerService) DefaultIndexName() string {
	if s == nil || s.manager == nil {
		return "rag_chunks_" + time.Now().UTC().Format("20060102150405")
	}
	return s.manager.DefaultIndexName() + "_" + time.Now().UTC().Format("20060102150405")
}

func (s *RagIndexManagerService) AliasName() string {
	if s == nil || s.manager == nil {
		return ""
	}
	return s.manager.AliasName()
}
