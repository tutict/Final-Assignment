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

type stubAppealService struct {
	mine []domain.AppealManagement
}

func (s stubAppealService) CheckAndInsertIdempotency(string, *domain.AppealManagement, string) (*domain.AppealManagement, error) {
	return nil, nil
}
func (s stubAppealService) CountAppealsByStatus(string) (int64, error) { return 0, nil }
func (s stubAppealService) DeleteAppeal(uint) error                    { return nil }
func (s stubAppealService) GetAllAppeals() ([]domain.AppealManagement, error) {
	return s.mine, nil
}
func (s stubAppealService) GetAppealByID(uint) (*domain.AppealManagement, error) {
	return &s.mine[0], nil
}
func (s stubAppealService) GetAppealsByAppellantName(string) ([]domain.AppealManagement, error) {
	return s.mine, nil
}
func (s stubAppealService) GetAppealsByContactNumber(string) ([]domain.AppealManagement, error) {
	return s.mine, nil
}
func (s stubAppealService) GetAppealsByIdCardNumber(string) ([]domain.AppealManagement, error) {
	return s.mine, nil
}
func (s stubAppealService) GetAppealsByOffenseID(uint) ([]domain.AppealManagement, error) {
	return s.mine, nil
}
func (s stubAppealService) GetAppealsByProcessStatus(string) ([]domain.AppealManagement, error) {
	return s.mine, nil
}
func (s stubAppealService) GetAppealsByTimeRange(time.Time, time.Time) ([]domain.AppealManagement, error) {
	return s.mine, nil
}
func (s stubAppealService) GetOffenseByAppealID(uint) (*domain.OffenseInformation, error) {
	return nil, nil
}
func (s stubAppealService) ListForRequester(string, bool) ([]domain.AppealManagement, error) {
	return s.mine, nil
}
func (s stubAppealService) FilterForRequester(_ string, _ bool, appeals []domain.AppealManagement) []domain.AppealManagement {
	return appeals
}
func (s stubAppealService) CanAccess(string, bool, *domain.AppealManagement) bool { return true }

func TestGetMyAppealsIsNotCapturedByIDRoute(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "ce@ce.com")
		c.Set("role", "USER")
		c.Set("normalizedRoles", []string{"USER"})
		c.Next()
	})
	handler := NewAppealHandler(stubAppealService{mine: []domain.AppealManagement{
		{AppealID: 7, AppealNumber: "AP-MINE"},
	}})
	group := router.Group("/api/appeals")
	group.GET("/my", handler.GetMyAppeals)
	group.GET("/:id", handler.GetAppealByID)

	res := httptest.NewRecorder()
	router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, "/api/appeals/my?page=1&size=10", nil))
	if res.Code != http.StatusOK {
		t.Fatalf("GET /api/appeals/my = %d body=%s", res.Code, res.Body.String())
	}
	var got []domain.AppealManagement
	if err := json.Unmarshal(res.Body.Bytes(), &got); err != nil {
		t.Fatalf("decode: %v body=%s", err, res.Body.String())
	}
	if len(got) != 1 || got[0].AppealNumber != "AP-MINE" {
		t.Fatalf("expected current-user appeals, got %#v", got)
	}
}
