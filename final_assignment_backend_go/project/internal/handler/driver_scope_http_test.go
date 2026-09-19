package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type stubDriverService struct {
	listed []domain.DriverInformation
}

func (s stubDriverService) CheckAndInsertIdempotency(string, *domain.DriverInformation, string) error {
	return nil
}
func (s stubDriverService) DeleteDriver(int) error { return nil }
func (s stubDriverService) GetAllDrivers() ([]domain.DriverInformation, error) {
	return s.listed, nil
}
func (s stubDriverService) GetDriverById(int) (*domain.DriverInformation, error) {
	return &s.listed[0], nil
}
func (s stubDriverService) SearchByIdCardNumber(string, int, int) ([]domain.DriverInformation, error) {
	return s.listed, nil
}
func (s stubDriverService) SearchByLicenseNumber(string, int, int) ([]domain.DriverInformation, error) {
	return s.listed, nil
}
func (s stubDriverService) SearchByName(string, int, int) ([]domain.DriverInformation, error) {
	return s.listed, nil
}
func (s stubDriverService) ListForRequester(_ string, elevated bool) ([]domain.DriverInformation, error) {
	if elevated {
		return s.listed, nil
	}
	return s.listed[:1], nil
}
func (s stubDriverService) FilterForRequester(_ string, elevated bool, drivers []domain.DriverInformation) []domain.DriverInformation {
	if elevated {
		return drivers
	}
	return drivers[:1]
}
func (s stubDriverService) CanAccess(_ string, elevated bool, _ *domain.DriverInformation) bool {
	return elevated
}

type stubUsers struct{}

func (stubUsers) CheckAndInsertIdempotency(string, *domain.UserManagement, string) error {
	return nil
}
func (stubUsers) DeleteUserByID(string) error          { return nil }
func (stubUsers) DeleteUserByUsername(string) error    { return nil }
func (stubUsers) GetAllUsers() ([]domain.UserManagement, error) {
	return nil, nil
}
func (stubUsers) GetPhoneNumbersByPrefixGlobally(string) ([]string, error) { return nil, nil }
func (stubUsers) GetStatusesByPrefixGlobally(string) ([]string, error)    { return nil, nil }
func (stubUsers) GetUserByID(string) (*domain.UserManagement, error)      { return nil, nil }
func (stubUsers) GetUserById(int) (*domain.UserManagement, error)         { return nil, nil }
func (stubUsers) GetUserByUsername(string) (*domain.UserManagement, error) {
	return nil, nil
}
func (stubUsers) GetUsernamesByPrefixGlobally(string) ([]string, error) { return nil, nil }
func (stubUsers) GetUsersByRole(string) ([]domain.UserManagement, error) {
	return nil, nil
}
func (stubUsers) GetUsersByStatus(string) ([]domain.UserManagement, error) {
	return nil, nil
}
func (stubUsers) IsUsernameExists(string) bool { return false }
func (stubUsers) UpdateUser(*domain.UserManagement) error { return nil }
func (stubUsers) UpdateUserByID(string, *domain.UserManagement, string) error {
	return nil
}

func TestDriverListIsScopedForUser(t *testing.T) {
	gin.SetMode(gin.TestMode)
	authID := int64(12)
	svc := stubDriverService{listed: []domain.DriverInformation{
		{DriverID: 1, AuthUserID: &authID, Name: "mine"},
		{DriverID: 2, Name: "other"},
	}}
	ctrl := NewDriverInformationController(svc, stubUsers{})
	r := gin.New()
	ctrl.RegisterRoutes(r)

	req := httptest.NewRequest(http.MethodGet, "/api/drivers", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req
	c.Set("username", "driver1")
	c.Set("role", "USER")
	c.Set("normalizedRoles", []string{"USER"})
	ctrl.GetAllDrivers(c)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", w.Code, w.Body.String())
	}
	var got []domain.DriverInformation
	if err := json.Unmarshal(w.Body.Bytes(), &got); err != nil {
		t.Fatal(err)
	}
	if len(got) != 1 || got[0].Name != "mine" {
		t.Fatalf("user should only see own driver, got %#v", got)
	}
}

func TestDriverCreateRejectedForUser(t *testing.T) {
	gin.SetMode(gin.TestMode)
	ctrl := NewDriverInformationController(stubDriverService{}, stubUsers{})
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodPost, "/api/drivers", nil)
	c.Set("role", "USER")
	c.Set("normalizedRoles", []string{"USER"})
	ctrl.CreateDriver(c)
	if w.Code != http.StatusForbidden {
		t.Fatalf("status=%d", w.Code)
	}
}
