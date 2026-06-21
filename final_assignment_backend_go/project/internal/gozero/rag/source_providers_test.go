package rag

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/domain"
)

func TestExtractOffenseTypeDictSourceMatchesSpringShape(t *testing.T) {
	updatedAt := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
	fine := 200.0
	points := 3

	source := ExtractOffenseTypeDictSource(domain.OffenseTypeDict{
		TypeID:                7,
		OffenseCode:           "A001",
		OffenseName:           "Illegal parking",
		Category:              "Parking",
		Description:           "Vehicle stopped in a restricted area",
		StandardFineAmount:    &fine,
		DeductedPoints:        &points,
		SeverityLevel:         "Minor",
		Status:                "Active",
		UpdatedAt:             &updatedAt,
		LicenseSuspensionDays: nil,
	})

	if source.SourceTable != "offense_type_dict" || source.SourceID != "7" {
		t.Fatalf("unexpected source identity: %+v", source)
	}
	if source.Title != "A001 - Illegal parking" {
		t.Fatalf("Title = %q", source.Title)
	}
	for _, want := range []string{
		"offense_code: A001",
		"description: Vehicle stopped in a restricted area",
		"standard_fine_amount: 200",
		"deducted_points: 3",
	} {
		if !strings.Contains(source.Content, want) {
			t.Fatalf("Content missing %q: %s", want, source.Content)
		}
	}
	var metadata map[string]any
	if err := json.Unmarshal([]byte(source.MetadataJSON), &metadata); err != nil {
		t.Fatalf("metadata is not JSON: %v", err)
	}
	if metadata["source"] != "offense_type_dict" || metadata["severity_level"] != "Minor" {
		t.Fatalf("unexpected metadata: %+v", metadata)
	}
}

func TestExtractAppealRecordSourceMatchesSpringShape(t *testing.T) {
	offenseID := int64(42)
	appealTime := time.Date(2026, 2, 3, 4, 5, 6, 0, time.UTC)

	source := ExtractAppealRecordSource(domain.AppealRecord{
		AppealID:            11,
		AppealNumber:        "AP-2026-0001",
		OffenseID:           &offenseID,
		AppellantName:       "Alice",
		AppealType:          "Judgment_Error",
		AppealReason:        "Evidence does not match the vehicle",
		AppealTime:          &appealTime,
		EvidenceDescription: "Camera frame mismatch",
		AcceptanceStatus:    "Accepted",
		ProcessStatus:       "Under_Review",
	})

	if source.SourceTable != "appeal_record" || source.SourceID != "11" || source.ACLScope != "USER" {
		t.Fatalf("unexpected source identity: %+v", source)
	}
	if source.Title != "AP-2026-0001" {
		t.Fatalf("Title = %q", source.Title)
	}
	for _, want := range []string{
		"appeal_number: AP-2026-0001",
		"offense_id: 42",
		"appeal_reason: Evidence does not match the vehicle",
		"evidence_description: Camera frame mismatch",
	} {
		if !strings.Contains(source.Content, want) {
			t.Fatalf("Content missing %q: %s", want, source.Content)
		}
	}
}
