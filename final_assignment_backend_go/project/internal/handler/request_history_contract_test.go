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

type historyStub struct {
	rows []domain.SysRequestHistory
}

func (s historyStub) ListSysRequestHistory() ([]domain.SysRequestHistory, error) {
	return s.rows, nil
}

func TestRequestHistorySearchMatchesFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	when, _ := time.Parse("2006-01-02T15:04:05", "2026-09-30T11:00:00")
	later := when.Add(48 * time.Hour)
	businessID := int64(15)
	userID := int64(7)
	router := gin.New()
	NewSystemLogsController(nil).WithRequestHistory(historyStub{rows: []domain.SysRequestHistory{
		{ID: 1, IdempotencyKey: "appeal-1", RequestMethod: "POST", RequestURL: "/api/appeals", BusinessType: "Appeal", BusinessID: &businessID, BusinessStatus: "SUCCESS", UserID: &userID, RequestIP: "10.0.0.8", CreatedAt: when},
		{ID: 2, IdempotencyKey: "fine-2", RequestMethod: "PUT", RequestURL: "/api/fines/3", BusinessType: "Fine", BusinessStatus: "FAILED", RequestIP: "10.1.1.9", CreatedAt: later},
	}}).RegisterRoutes(router)

	assertOne := func(path string, wantID int64) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.SysRequestHistory
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].ID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}

	assertOne("/api/system/logs/requests/search/idempotency?key=appeal", 1)
	assertOne("/api/system/logs/requests/search/method?requestMethod=PUT", 2)
	assertOne("/api/system/logs/requests/search/url?requestUrl=/api/appeals", 1)
	assertOne("/api/system/logs/requests/search/business-type?businessType=Fine", 2)
	assertOne("/api/system/logs/requests/search/business-id?businessId=15", 1)
	assertOne("/api/system/logs/requests/search/status?status=FAILED", 2)
	assertOne("/api/system/logs/requests/search/user?userId=7", 1)
	assertOne("/api/system/logs/requests/search/ip?requestIp=10.0.0", 1)
	assertOne("/api/system/logs/requests/search/time-range?startTime=2026-09-30&endTime=2026-09-30", 1)

	one := httptest.NewRecorder()
	router.ServeHTTP(one, httptest.NewRequest(http.MethodGet, "/api/system/logs/requests/1", nil))
	if one.Code != http.StatusOK {
		t.Fatalf("detail status=%d body=%s", one.Code, one.Body.String())
	}
	var row domain.SysRequestHistory
	if err := json.Unmarshal(one.Body.Bytes(), &row); err != nil {
		t.Fatal(err)
	}
	if row.IdempotencyKey != "appeal-1" || row.RequestMethod != "POST" {
		t.Fatalf("detail=%#v", row)
	}
}
