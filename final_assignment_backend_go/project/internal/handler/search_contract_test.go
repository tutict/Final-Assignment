package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

func TestDriverNameSearchUsesFrontendContract(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var got string
	drivers := stubDriverService{
		listed:        []domain.DriverInformation{{DriverID: 4, Name: "张三"}},
		lastNameQuery: &got,
	}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "admin")
		c.Set("normalizedRoles", []string{"ADMIN"})
		c.Next()
	})
	NewDriverInformationController(drivers, stubUsers{}).RegisterRoutes(router)

	res := httptest.NewRecorder()
	router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, "/api/drivers/search/name?keywords=张三&page=1&size=20", nil))
	if res.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if got != "张三" {
		t.Fatalf("keywords not forwarded: %q", got)
	}
	var body []domain.DriverInformation
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode: %v body=%s", err, res.Body.String())
	}
	if len(body) != 1 || body[0].Name != "张三" {
		t.Fatalf("body=%#v", body)
	}
}

type contractVehicles struct {
	byPlate map[string]*domain.VehicleInformation
}

func (contractVehicles) CreateVehicle(string, *domain.VehicleInformation) error { return nil }
func (contractVehicles) DeleteById(int) error                                   { return nil }
func (contractVehicles) DeleteByLicensePlate(string) error                      { return nil }
func (contractVehicles) GetAll() []domain.VehicleInformation                    { return nil }
func (contractVehicles) GetById(int) (*domain.VehicleInformation, error)        { return nil, nil }
func (contractVehicles) GetByIdCardNumber(string) []domain.VehicleInformation   { return nil }
func (s contractVehicles) GetByLicensePlate(plate string) (*domain.VehicleInformation, error) {
	return s.byPlate[plate], nil
}
func (contractVehicles) GetByOwnerName(string) []domain.VehicleInformation { return nil }
func (contractVehicles) GetByDriverId(int) []domain.VehicleInformation     { return nil }
func (contractVehicles) GetByStatus(string) []domain.VehicleInformation    { return nil }
func (contractVehicles) GetByType(string) []domain.VehicleInformation      { return nil }
func (contractVehicles) GetLicensePlateAutocomplete(string, string, int) []string {
	return nil
}
func (contractVehicles) GetLicensePlateGlobally(string) []string { return nil }
func (contractVehicles) GetVehicleTypeAutocomplete(string, string, int) []string {
	return nil
}
func (contractVehicles) GetVehicleTypeGlobally(string) []string { return nil }
func (contractVehicles) IsLicensePlateExists(string) bool       { return false }
func (contractVehicles) SearchVehicles(string, int, int) ([]domain.VehicleInformation, error) {
	return nil, nil
}
func (contractVehicles) UpdateVehicle(string, *domain.VehicleInformation) error { return nil }
func (contractVehicles) ListForRequester(string, bool) []domain.VehicleInformation {
	return nil
}
func (contractVehicles) FilterForRequester(_ string, _ bool, list []domain.VehicleInformation) []domain.VehicleInformation {
	return list
}
func (contractVehicles) CanAccess(string, bool, *domain.VehicleInformation) bool { return true }

func TestVehicleLicenseSearchUsesFrontendContract(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "admin")
		c.Set("normalizedRoles", []string{"ADMIN"})
		c.Next()
	})
	NewVehicleController(contractVehicles{byPlate: map[string]*domain.VehicleInformation{
		"粤A12345": {VehicleID: 9, LicensePlate: "粤A12345"},
	}}).RegisterRoutes(router)

	res := httptest.NewRecorder()
	router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, "/api/vehicles/search/license?licensePlate=粤A12345", nil))
	if res.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	var body domain.VehicleInformation
	if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode: %v body=%s", err, res.Body.String())
	}
	if body.VehicleID != 9 {
		t.Fatalf("body=%#v", body)
	}
}
