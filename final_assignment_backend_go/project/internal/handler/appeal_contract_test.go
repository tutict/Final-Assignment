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

func TestAppealSearchRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	when, _ := time.Parse("2006-01-02T15:04:05", "2026-09-30T10:00:00")
	items := []domain.AppealManagement{
		{AppealID: 1, AppealNumber: "AP-100", AppellantName: "Zhang", AppellantIDCard: "110101199001011234", AcceptanceStatus: "Pending", ProcessStatus: "Unprocessed", AcceptanceHandler: "Li", AppealTime: when},
		{AppealID: 2, AppealNumber: "BX-200", AppellantName: "Wang", AppellantIDCard: "310101199202023456", AcceptanceStatus: "Accepted", ProcessStatus: "Processed", ProcessHandler: "Zhao", AppealTime: when.Add(48 * time.Hour)},
	}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "admin")
		c.Set("normalizedRoles", []string{"ADMIN"})
		c.Next()
	})
	NewAppealHandler(stubAppealService{mine: items}).RegisterSearchRoutes(router.Group("/api/appeals"))

	assertOne := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.AppealManagement
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s decode: %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].AppealID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}

	assertOne("/api/appeals/search/number/prefix?appealNumber=AP-", 1)
	assertOne("/api/appeals/search/number/fuzzy?appealNumber=200", 2)
	assertOne("/api/appeals/search/appellant/name/prefix?appellantName=Zha", 1)
	assertOne("/api/appeals/search/appellant/id-card?appellantIdCard=310101", 2)
	assertOne("/api/appeals/search/acceptance-status?acceptanceStatus=Pending", 1)
	assertOne("/api/appeals/search/process-status?processStatus=Processed", 2)
	assertOne("/api/appeals/search/handler?acceptanceHandler=Zhao", 2)
	assertOne("/api/appeals/search/time-range?startTime=2026-09-30&endTime=2026-09-30", 1)
}
