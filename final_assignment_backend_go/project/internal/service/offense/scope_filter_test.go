package offense

import (
	"testing"

	"final_assignment_backend_go/project/internal/domain"
)

func TestFilterFinesElevatedPassthrough(t *testing.T) {
	s := &FineInformationService{}
	in := []domain.FineInformation{{FineID: 1}, {FineID: 2}}
	got := s.FilterForRequester("anyone", true, in)
	if len(got) != 2 {
		t.Fatalf("elevated filter len=%d", len(got))
	}
}

func TestFilterDeductionsElevatedPassthrough(t *testing.T) {
	s := &DeductionInformationService{}
	in := []domain.DeductionInformation{{DeductionID: 4, DriverID: 8}}
	got := s.FilterForRequester("anyone", true, in)
	if len(got) != 1 {
		t.Fatalf("len=%d", len(got))
	}
}
