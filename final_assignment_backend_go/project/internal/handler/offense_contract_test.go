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

func TestOffenseSearchRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	driverA := 3
	driverB := 4
	when, _ := time.Parse("2006-01-02T15:04:05", "2026-09-30T10:00:00")
	items := []domain.OffenseInformation{
		{OffenseID: 1, OffenseCode: "A01", ProcessStatus: "Pending", VehicleID: 7, DriverID: &driverA, OffenseNumber: "OF-1", FineAmount: 20, OffenseTime: when},
		{OffenseID: 2, OffenseCode: "B02", ProcessStatus: "Closed", VehicleID: 8, DriverID: &driverB, OffenseNumber: "OF-2", FineAmount: 200, OffenseTime: when.Add(48 * time.Hour)},
	}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "admin")
		c.Set("normalizedRoles", []string{"ADMIN"})
		c.Next()
	})
	(&OffenseInformationController{Service: stubOffenseService{listed: items}}).RegisterRoutes(router.Group(""))

	assertOne := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.OffenseInformation
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s decode: %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].OffenseID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}

	assertOne("/api/offenses/vehicle/7", 1)
	assertOne("/api/offenses/search/status?status=Pending", 1)
	assertOne("/api/offenses/search/code?offenseCode=A01", 1)
	assertOne("/api/offenses/search/number?offenseNumber=OF-2", 2)
	assertOne("/api/offenses/search/fine-range?minAmount=10&maxAmount=50", 1)
	assertOne("/api/offenses/search/time-range?startTime=2026-09-30&endTime=2026-09-30", 1)
}
