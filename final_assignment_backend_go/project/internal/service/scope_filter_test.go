package service

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

func TestFilterDriversElevatedPassthrough(t *testing.T) {
	s := &DriverInformationService{}
	in := []domain.DriverInformation{{DriverID: 9}}
	got := s.FilterForRequester("anyone", true, in)
	if len(got) != 1 || got[0].DriverID != 9 {
		t.Fatalf("unexpected %+v", got)
	}
}

func TestFilterVehiclesElevatedPassthrough(t *testing.T) {
	s := &VehicleService{}
	in := []domain.VehicleInformation{{VehicleID: 3}}
	got := s.FilterForRequester("anyone", true, in)
	if len(got) != 1 || got[0].VehicleID != 3 {
		t.Fatalf("unexpected %+v", got)
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
