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

func ginWithRole(role, username string) *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", username)
		c.Set("role", role)
		c.Set("normalizedRoles", []string{role})
		c.Next()
	})
	router.Use(AccessPolicy())
	return router
}

func serve(router http.Handler, method, path string) *httptest.ResponseRecorder {
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, httptest.NewRequest(method, path, nil))
	return recorder
}

func scoped[T any](elevated bool, items []T) []T {
	if elevated || len(items) == 0 {
		return items
	}
	return items[:1]
}

func TestAccessPolicyHitsGinGovernancePaths(t *testing.T) {
	cases := []struct {
		role string
		path string
		want int
	}{
		{"USER", "/api/users", http.StatusForbidden},
		{"USER", "/api/users/me", http.StatusNoContent},
		{"USER", "/api/rag/admin", http.StatusForbidden},
		{"USER", "/api/logs/login", http.StatusForbidden},
		{"USER", "/api/system/settings", http.StatusForbidden},
		{"USER", "/api/drivers", http.StatusNoContent},
		{"TRAFFIC_POLICE", "/api/users", http.StatusForbidden},
		{"FINANCE", "/api/users", http.StatusForbidden},
		{"FINANCE", "/api/logs/login", http.StatusForbidden},
		{"ADMIN", "/api/users", http.StatusNoContent},
		{"SUPER_ADMIN", "/api/users", http.StatusNoContent},
		{"SUPER_ADMIN", "/api/rag/admin", http.StatusNoContent},
		{"ADMIN", "/api/system/settings", http.StatusNoContent},
	}
	for _, tc := range cases {
		router := ginWithRole(tc.role, "tester")
		ok := func(c *gin.Context) { c.Status(http.StatusNoContent) }
		router.GET("/api/users", ok)
		router.GET("/api/users/me", ok)
		router.GET("/api/rag/admin", ok)
		router.GET("/api/logs/login", ok)
		router.GET("/api/system/settings", ok)
		router.GET("/api/drivers", ok)
		res := serve(router, http.MethodGet, tc.path)
		if res.Code != tc.want {
			t.Fatalf("%s GET %s = %d want %d", tc.role, tc.path, res.Code, tc.want)
		}
	}
}

type stubVehicleService struct {
	listed []domain.VehicleInformation
}

func (s stubVehicleService) CreateVehicle(string, *domain.VehicleInformation) error { return nil }
func (s stubVehicleService) DeleteById(int) error                                   { return nil }
func (s stubVehicleService) DeleteByLicensePlate(string) error                      { return nil }
func (s stubVehicleService) GetAll() []domain.VehicleInformation                    { return s.listed }
func (s stubVehicleService) GetById(int) (*domain.VehicleInformation, error) {
	return &s.listed[0], nil
}
func (s stubVehicleService) GetByIdCardNumber(string) []domain.VehicleInformation { return s.listed }
func (s stubVehicleService) GetByLicensePlate(string) (*domain.VehicleInformation, error) {
	return &s.listed[0], nil
}
func (s stubVehicleService) GetByOwnerName(string) []domain.VehicleInformation { return s.listed }
func (s stubVehicleService) GetByDriverId(int) []domain.VehicleInformation     { return s.listed }
func (s stubVehicleService) GetByStatus(string) []domain.VehicleInformation    { return s.listed }
func (s stubVehicleService) GetByType(string) []domain.VehicleInformation      { return s.listed }
func (s stubVehicleService) GetLicensePlateAutocomplete(string, string, int) []string {
	return []string{"A"}
}
func (s stubVehicleService) GetLicensePlateGlobally(string) []string { return []string{"A"} }
func (s stubVehicleService) GetVehicleTypeAutocomplete(string, string, int) []string {
	return []string{"car"}
}
func (s stubVehicleService) GetVehicleTypeGlobally(string) []string { return []string{"car"} }
func (s stubVehicleService) IsLicensePlateExists(string) bool       { return false }
func (s stubVehicleService) SearchVehicles(string, int, int) ([]domain.VehicleInformation, error) {
	return s.listed, nil
}
func (s stubVehicleService) UpdateVehicle(string, *domain.VehicleInformation) error { return nil }
func (s stubVehicleService) ListForRequester(_ string, elevated bool) []domain.VehicleInformation {
	return scoped(elevated, s.listed)
}
func (s stubVehicleService) FilterForRequester(_ string, elevated bool, vehicles []domain.VehicleInformation) []domain.VehicleInformation {
	return scoped(elevated, vehicles)
}
func (s stubVehicleService) CanAccess(_ string, elevated bool, _ *domain.VehicleInformation) bool {
	return elevated
}

type stubFineHTTPService struct {
	listed []domain.FineInformation
}

func (s stubFineHTTPService) CheckAndInsertIdempotency(string, *domain.FineInformation, string) error {
	return nil
}
func (s stubFineHTTPService) DeleteFine(string) error { return nil }
func (s stubFineHTTPService) GetAllFines() ([]domain.FineInformation, error) {
	return s.listed, nil
}
func (s stubFineHTTPService) GetFineByID(string) (*domain.FineInformation, error) {
	return &s.listed[0], nil
}
func (s stubFineHTTPService) GetFineByReceiptNumber(string) (*domain.FineInformation, error) {
	return &s.listed[0], nil
}
func (s stubFineHTTPService) GetFinesByPayee(string) ([]domain.FineInformation, error) {
	return s.listed, nil
}
func (s stubFineHTTPService) GetFinesByTimeRange(time.Time, time.Time) ([]domain.FineInformation, error) {
	return s.listed, nil
}
func (s stubFineHTTPService) GetFinesByDriverID(int) ([]domain.FineInformation, error) {
	return s.listed, nil
}
func (s stubFineHTTPService) GetFinesByOffenseID(int) ([]domain.FineInformation, error) {
	return s.listed, nil
}
func (s stubFineHTTPService) ListForRequester(_ string, elevated bool) ([]domain.FineInformation, error) {
	return scoped(elevated, s.listed), nil
}
func (s stubFineHTTPService) FilterForRequester(_ string, elevated bool, fines []domain.FineInformation) []domain.FineInformation {
	return scoped(elevated, fines)
}
func (s stubFineHTTPService) CanAccess(_ string, elevated bool, _ *domain.FineInformation) bool {
	return elevated
}
func (s stubFineHTTPService) SearchByFineTimeRange(time.Time, time.Time, string) ([]domain.FineInformation, error) {
	return s.listed, nil
}
func (s stubFineHTTPService) SearchByPaymentStatus(string, int, int) ([]domain.FineInformation, error) {
	return s.listed, nil
}

type stubOffenseService struct {
	listed []domain.OffenseInformation
}

func (s stubOffenseService) CheckAndInsertIdempotency(string, *domain.OffenseInformation, string) error {
	return nil
}
func (s stubOffenseService) DeleteOffense(int) error { return nil }
func (s stubOffenseService) GetAllOffenses() ([]domain.OffenseInformation, error) {
	return s.listed, nil
}
func (s stubOffenseService) GetOffenseByID(int) (*domain.OffenseInformation, error) {
	return &s.listed[0], nil
}
func (s stubOffenseService) GetOffensesByTimeRange(time.Time, time.Time) ([]domain.OffenseInformation, error) {
	return s.listed, nil
}
func (s stubOffenseService) SearchByDriverName(string, int, int) ([]domain.OffenseInformation, error) {
	return s.listed, nil
}
func (s stubOffenseService) SearchByLicensePlate(string, int, int) ([]domain.OffenseInformation, error) {
	return s.listed, nil
}
func (s stubOffenseService) SearchByOffenseType(string, int, int) ([]domain.OffenseInformation, error) {
	return s.listed, nil
}
func (s stubOffenseService) ListForRequester(_ string, elevated bool) ([]domain.OffenseInformation, error) {
	return scoped(elevated, s.listed), nil
}
func (s stubOffenseService) FilterForRequester(_ string, elevated bool, offenses []domain.OffenseInformation) []domain.OffenseInformation {
	return scoped(elevated, offenses)
}
func (s stubOffenseService) CanAccess(_ string, elevated bool, _ *domain.OffenseInformation) bool {
	return elevated
}

func TestPolicyTableWriteAndScopeHitGin(t *testing.T) {
	authID := int64(12)
	drivers := []domain.DriverInformation{
		{DriverID: 1, AuthUserID: &authID, Name: "mine"},
		{DriverID: 2, Name: "other"},
	}
	vehicles := []domain.VehicleInformation{
		{VehicleID: 1, LicensePlate: "mine"},
		{VehicleID: 2, LicensePlate: "other"},
	}
	fines := []domain.FineInformation{
		{FineID: 1, FineNumber: "mine"},
		{FineID: 2, FineNumber: "other"},
	}

	newRouter := func(role string) *gin.Engine {
		router := ginWithRole(role, "driver1")
		NewDriverInformationController(stubDriverService{listed: drivers}, stubUsers{}).RegisterRoutes(router)
		NewVehicleController(stubVehicleService{listed: vehicles}).RegisterRoutes(router)
		fine := NewFineController(stubFineHTTPService{listed: fines})
		group := router.Group("/api/fines")
		group.POST("", fine.CreateFine)
		group.GET("", fine.GetAllFines)
		offense := &OffenseInformationController{Service: stubOffenseService{listed: []domain.OffenseInformation{
			{OffenseID: 1, OffenseType: "mine"},
			{OffenseID: 2, OffenseType: "other"},
		}}}
		offense.RegisterRoutes(router.Group(""))
		return router
	}

	t.Run("user driver list is scoped", func(t *testing.T) {
		res := serve(newRouter("USER"), http.MethodGet, "/api/drivers")
		if res.Code != http.StatusOK {
			t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
		}
		var got []domain.DriverInformation
		if err := json.Unmarshal(res.Body.Bytes(), &got); err != nil {
			t.Fatal(err)
		}
		if len(got) != 1 || got[0].Name != "mine" {
			t.Fatalf("user should only see own driver, got %#v", got)
		}
	})

	t.Run("admin driver list is unscoped", func(t *testing.T) {
		res := serve(newRouter("ADMIN"), http.MethodGet, "/api/drivers")
		if res.Code != http.StatusOK {
			t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
		}
		var got []domain.DriverInformation
		if err := json.Unmarshal(res.Body.Bytes(), &got); err != nil {
			t.Fatal(err)
		}
		if len(got) != 2 {
			t.Fatalf("admin should see all drivers, got %#v", got)
		}
	})

	writeCases := []struct {
		name   string
		role   string
		method string
		path   string
		want   int
	}{
		{"user cannot create driver", "USER", http.MethodPost, "/api/drivers", http.StatusForbidden},
		{"finance cannot create driver", "FINANCE", http.MethodPost, "/api/drivers", http.StatusForbidden},
		{"police can pass driver write gate", "TRAFFIC_POLICE", http.MethodPost, "/api/drivers", http.StatusBadRequest},
		{"admin can pass driver write gate", "ADMIN", http.MethodPost, "/api/drivers", http.StatusBadRequest},
		{"user cannot create vehicle", "USER", http.MethodPost, "/api/vehicles", http.StatusForbidden},
		{"user cannot create offense", "USER", http.MethodPost, "/api/offenses", http.StatusForbidden},
		{"police can pass offense write gate", "TRAFFIC_POLICE", http.MethodPost, "/api/offenses", http.StatusBadRequest},
		{"user cannot create fine", "USER", http.MethodPost, "/api/fines", http.StatusForbidden},
		{"police can pass fine write gate", "TRAFFIC_POLICE", http.MethodPost, "/api/fines", http.StatusBadRequest},
		{"finance can pass fine write gate", "FINANCE", http.MethodPost, "/api/fines", http.StatusBadRequest},
		{"user cannot search driver id card", "USER", http.MethodGet, "/api/drivers/by-id-card?query=x", http.StatusForbidden},
		{"admin can search driver id card", "ADMIN", http.MethodGet, "/api/drivers/by-id-card?query=x", http.StatusOK},
		{"user cannot global vehicle autocomplete", "USER", http.MethodGet, "/api/vehicles/autocomplete/license-plate-globally/me", http.StatusForbidden},
		{"finance can global vehicle autocomplete", "FINANCE", http.MethodGet, "/api/vehicles/autocomplete/license-plate-globally/me", http.StatusOK},
	}
	for _, tc := range writeCases {
		t.Run(tc.name, func(t *testing.T) {
			res := serve(newRouter(tc.role), tc.method, tc.path)
			if res.Code != tc.want {
				t.Fatalf("%s %s %s = %d want %d body=%s", tc.role, tc.method, tc.path, res.Code, tc.want, res.Body.String())
			}
		})
	}

	t.Run("user vehicle list is scoped", func(t *testing.T) {
		res := serve(newRouter("USER"), http.MethodGet, "/api/vehicles")
		if res.Code != http.StatusOK {
			t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
		}
		var got []domain.VehicleInformation
		if err := json.Unmarshal(res.Body.Bytes(), &got); err != nil {
			t.Fatal(err)
		}
		if len(got) != 1 || got[0].LicensePlate != "mine" {
			t.Fatalf("user should only see own vehicle, got %#v", got)
		}
	})

	t.Run("user fine list is scoped", func(t *testing.T) {
		res := serve(newRouter("USER"), http.MethodGet, "/api/fines")
		if res.Code != http.StatusOK {
			t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
		}
		var got []domain.FineInformation
		if err := json.Unmarshal(res.Body.Bytes(), &got); err != nil {
			t.Fatal(err)
		}
		if len(got) != 1 || got[0].FineNumber != "mine" {
			t.Fatalf("user should only see own fine, got %#v", got)
		}
	})

	t.Run("user offense list is scoped", func(t *testing.T) {
		res := serve(newRouter("USER"), http.MethodGet, "/api/offenses")
		if res.Code != http.StatusOK {
			t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
		}
		var got []domain.OffenseInformation
		if err := json.Unmarshal(res.Body.Bytes(), &got); err != nil {
			t.Fatal(err)
		}
		if len(got) != 1 || got[0].OffenseType != "mine" {
			t.Fatalf("user should only see own offense, got %#v", got)
		}
	})
}
