package driver

import (
	"testing"

	"final_assignment_backend_go/project/internal/domain"
)

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
