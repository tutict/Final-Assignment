package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type deductionStub struct {
	items []domain.DeductionInformation
}

func (deductionStub) CheckAndInsertIdempotency(string, *domain.DeductionInformation, string) error {
	return nil
}
func (deductionStub) DeleteDeduction(string) error { return nil }
func (s deductionStub) GetAllDeductions() ([]domain.DeductionInformation, error) {
	return s.items, nil
}
func (deductionStub) GetDeductionById(string) (*domain.DeductionInformation, error) {
	return nil, nil
}
func (deductionStub) GetDeductionsByHandler(string) ([]domain.DeductionInformation, error) {
	return nil, nil
}
func (deductionStub) GetDeductionsByTimeRange(time.Time, time.Time) ([]domain.DeductionInformation, error) {
	return nil, nil
}
func (s deductionStub) SearchByDeductionTimeRange(time.Time, time.Time, int) ([]domain.DeductionInformation, error) {
	return s.items, nil
}
func (s deductionStub) SearchByHandler(string, int) ([]domain.DeductionInformation, error) {
	if len(s.items) == 0 {
		return nil, nil
	}
	return s.items[:1], nil
}
func (s deductionStub) ListForRequester(string, bool) ([]domain.DeductionInformation, error) {
	return s.items, nil
}
func (deductionStub) FilterForRequester(_ string, _ bool, items []domain.DeductionInformation) []domain.DeductionInformation {
	return items
}
func (deductionStub) CanAccess(string, bool, *domain.DeductionInformation) bool { return true }

func TestDeductionRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	items := []domain.DeductionInformation{
		{DeductionID: 1, OffenseID: 8, DriverID: 3, Status: "Active", Handler: "lisi"},
		{DeductionID: 2, OffenseID: 9, DriverID: 3, Status: "Restored", Handler: "wangwu"},
	}
	router := gin.New()
	NewDeductionInformationController(deductionStub{items: items}).RegisterRoutes(router)

	offense := httptest.NewRecorder()
	router.ServeHTTP(offense, httptest.NewRequest(http.MethodGet, "/api/deductions/offense/8", nil))
	if offense.Code != http.StatusOK {
		t.Fatalf("offense status=%d body=%s", offense.Code, offense.Body.String())
	}
	var byOffense []domain.DeductionInformation
	if err := json.Unmarshal(offense.Body.Bytes(), &byOffense); err != nil {
		t.Fatal(err)
	}
	if len(byOffense) != 1 || byOffense[0].DeductionID != 1 {
		t.Fatalf("offense filter=%#v", byOffense)
	}

	status := httptest.NewRecorder()
	router.ServeHTTP(status, httptest.NewRequest(http.MethodGet, "/api/deductions/search/status?status=Restored", nil))
	if status.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", status.Code, status.Body.String())
	}
	var byStatus []domain.DeductionInformation
	if err := json.Unmarshal(status.Body.Bytes(), &byStatus); err != nil {
		t.Fatal(err)
	}
	if len(byStatus) != 1 || byStatus[0].DeductionID != 2 {
		t.Fatalf("status filter=%#v", byStatus)
	}

	handlerRes := httptest.NewRecorder()
	router.ServeHTTP(handlerRes, httptest.NewRequest(http.MethodGet, "/api/deductions/search/handler?handler=lisi&size=5", nil))
	if handlerRes.Code != http.StatusOK {
		t.Fatalf("handler status=%d body=%s", handlerRes.Code, handlerRes.Body.String())
	}
	var byHandler []domain.DeductionInformation
	if err := json.Unmarshal(handlerRes.Body.Bytes(), &byHandler); err != nil {
		t.Fatal(err)
	}
	if len(byHandler) != 1 || byHandler[0].DeductionID != 1 {
		t.Fatalf("handler filter=%#v", byHandler)
	}
}
