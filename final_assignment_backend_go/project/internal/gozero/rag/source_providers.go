package rag

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"

	"gorm.io/gorm"
)

type OffenseTypeDictSourceProvider struct {
	db *gorm.DB
}

type AppealRecordSourceProvider struct {
	db *gorm.DB
}

func NewBusinessSourceProviders(db *gorm.DB) []service.RagSourceBatchProvider {
	if db == nil {
		return nil
	}
	return []service.RagSourceBatchProvider{
		&OffenseTypeDictSourceProvider{db: db},
		&AppealRecordSourceProvider{db: db},
	}
}

func (p *OffenseTypeDictSourceProvider) LoadBatch(ctx context.Context, page, size int) ([]domain.RagSourceDocument, bool, error) {
	page, size = normalizePageSize(page, size)
	var records []domain.OffenseTypeDict
	err := p.db.WithContext(ctx).
		Order("type_id ASC").
		Offset((page - 1) * size).
		Limit(size).
		Find(&records).Error
	if err != nil {
		return nil, false, fmt.Errorf("load offense_type_dict RAG source batch: %w", err)
	}

	sources := make([]domain.RagSourceDocument, 0, len(records))
	for _, record := range records {
		sources = append(sources, ExtractOffenseTypeDictSource(record))
	}
	return sources, len(records) == size, nil
}

func (p *AppealRecordSourceProvider) LoadBatch(ctx context.Context, page, size int) ([]domain.RagSourceDocument, bool, error) {
	page, size = normalizePageSize(page, size)
	var records []domain.AppealRecord
	err := p.db.WithContext(ctx).
		Order("appeal_id ASC").
		Offset((page - 1) * size).
		Limit(size).
		Find(&records).Error
	if err != nil {
		return nil, false, fmt.Errorf("load appeal_record RAG source batch: %w", err)
	}

	sources := make([]domain.RagSourceDocument, 0, len(records))
	for _, record := range records {
		sources = append(sources, ExtractAppealRecordSource(record))
	}
	return sources, len(records) == size, nil
}

func ExtractOffenseTypeDictSource(source domain.OffenseTypeDict) domain.RagSourceDocument {
	sourceID := fmt.Sprint(source.TypeID)
	title := firstNonBlank(
		joinNonBlank(" - ", source.OffenseCode, source.OffenseName),
		"Offense Type "+sourceID,
	)
	content := joinLines(
		line("offense_code", source.OffenseCode),
		line("offense_name", source.OffenseName),
		line("category", source.Category),
		line("description", source.Description),
		line("standard_fine_amount", source.StandardFineAmount),
		line("min_fine_amount", source.MinFineAmount),
		line("max_fine_amount", source.MaxFineAmount),
		line("deducted_points", source.DeductedPoints),
		line("detention_days", source.DetentionDays),
		line("license_suspension_days", source.LicenseSuspensionDays),
		line("severity_level", source.SeverityLevel),
		line("legal_basis", source.LegalBasis),
		line("status", source.Status),
		line("remarks", source.Remarks),
	)
	return domain.RagSourceDocument{
		SourceType:    "BUSINESS",
		SourceTable:   "offense_type_dict",
		SourceID:      sourceID,
		SourceVersion: sourceVersion(source.UpdatedAt, source.CreatedAt),
		Title:         title,
		Content:       content,
		ACLScope:      "PUBLIC",
		Route:         "/offense-types/" + sourceID,
		MetadataJSON: writeMetadata(map[string]any{
			"source":         "offense_type_dict",
			"offense_code":   blankToNil(source.OffenseCode),
			"category":       blankToNil(source.Category),
			"severity_level": blankToNil(source.SeverityLevel),
		}),
		SourceField: "description",
	}
}

func ExtractAppealRecordSource(source domain.AppealRecord) domain.RagSourceDocument {
	sourceID := fmt.Sprint(source.AppealID)
	title := firstNonBlank(source.AppealNumber, "Appeal "+sourceID)
	content := joinLines(
		line("appeal_number", source.AppealNumber),
		line("offense_id", source.OffenseID),
		line("appellant_name", source.AppellantName),
		line("appeal_type", source.AppealType),
		line("appeal_reason", source.AppealReason),
		line("appeal_time", source.AppealTime),
		line("evidence_description", source.EvidenceDescription),
		line("acceptance_status", source.AcceptanceStatus),
		line("rejection_reason", source.RejectionReason),
		line("process_status", source.ProcessStatus),
		line("process_result", source.ProcessResult),
		line("remarks", source.Remarks),
	)
	return domain.RagSourceDocument{
		SourceType:    "BUSINESS",
		SourceTable:   "appeal_record",
		SourceID:      sourceID,
		SourceVersion: sourceVersion(source.UpdatedAt, source.CreatedAt),
		Title:         title,
		Content:       content,
		ACLScope:      "USER",
		Route:         "/appeals/" + sourceID,
		MetadataJSON: writeMetadata(map[string]any{
			"source":            "appeal_record",
			"appeal_number":     blankToNil(source.AppealNumber),
			"appeal_type":       blankToNil(source.AppealType),
			"acceptance_status": blankToNil(source.AcceptanceStatus),
			"process_status":    blankToNil(source.ProcessStatus),
		}),
		SourceField: "appeal_reason",
	}
}

func normalizePageSize(page, size int) (int, int) {
	if page < 1 {
		page = 1
	}
	if size < 1 {
		size = 1
	}
	return page, size
}

func sourceVersion(updatedAt, createdAt *time.Time) string {
	if updatedAt != nil && !updatedAt.IsZero() {
		return updatedAt.Format(time.RFC3339Nano)
	}
	if createdAt != nil && !createdAt.IsZero() {
		return createdAt.Format(time.RFC3339Nano)
	}
	return "v1"
}

func line(key string, value any) string {
	text := valueText(value)
	if strings.TrimSpace(text) == "" {
		return ""
	}
	return key + ": " + text
}

func valueText(value any) string {
	switch typed := value.(type) {
	case nil:
		return ""
	case *string:
		if typed == nil {
			return ""
		}
		return *typed
	case *int:
		if typed == nil {
			return ""
		}
		return fmt.Sprint(*typed)
	case *int64:
		if typed == nil {
			return ""
		}
		return fmt.Sprint(*typed)
	case *float64:
		if typed == nil {
			return ""
		}
		return fmt.Sprintf("%g", *typed)
	case *time.Time:
		if typed == nil || typed.IsZero() {
			return ""
		}
		return typed.Format(time.RFC3339Nano)
	default:
		return fmt.Sprint(value)
	}
}

func joinLines(lines ...string) string {
	values := make([]string, 0, len(lines))
	for _, value := range lines {
		if strings.TrimSpace(value) != "" {
			values = append(values, value)
		}
	}
	return strings.Join(values, "\n")
}

func joinNonBlank(separator string, values ...string) string {
	parts := make([]string, 0, len(values))
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			parts = append(parts, strings.TrimSpace(value))
		}
	}
	return strings.Join(parts, separator)
}

func firstNonBlank(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return strings.TrimSpace(value)
}

func blankToNil(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	return value
}

func writeMetadata(metadata map[string]any) string {
	raw, err := json.Marshal(metadata)
	if err != nil {
		return "{}"
	}
	return string(raw)
}
