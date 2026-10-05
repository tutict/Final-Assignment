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

type loginLogStub struct {
	items []domain.LoginLog
}

func (loginLogStub) CheckAndInsertIdempotency(string, *domain.LoginLog, string) error { return nil }
func (loginLogStub) DeleteLoginLog(string) error                                      { return nil }
func (s loginLogStub) GetAllLoginLogs() ([]domain.LoginLog, error)                    { return s.items, nil }
func (loginLogStub) GetLoginLogByID(string) (*domain.LoginLog, error)                 { return nil, nil }
func (loginLogStub) GetLoginLogsByLoginResult(string) ([]domain.LoginLog, error) {
	return nil, nil
}
func (s loginLogStub) GetLoginLogsByTimeRange(start, end time.Time) ([]domain.LoginLog, error) {
	out := make([]domain.LoginLog, 0)
	for _, item := range s.items {
		if !item.LoginTime.Before(start) && !item.LoginTime.After(end) {
			out = append(out, item)
		}
	}
	return out, nil
}
func (loginLogStub) GetLoginLogsByUsername(string) ([]domain.LoginLog, error) { return nil, nil }
func (loginLogStub) GetLoginResultsByPrefixGlobally(string) []string          { return nil }
func (loginLogStub) GetUsernamesByPrefixGlobally(string) []string             { return nil }

type operationLogStub struct {
	items []domain.OperationLog
}

func (operationLogStub) CheckAndInsertIdempotency(string, *domain.OperationLog, string) error {
	return nil
}
func (operationLogStub) DeleteOperationLog(int) error { return nil }
func (s operationLogStub) GetAllOperationLogs() ([]domain.OperationLog, error) {
	return s.items, nil
}
func (operationLogStub) GetOperationLog(int) (*domain.OperationLog, error) { return nil, nil }
func (s operationLogStub) GetOperationLogsByResult(result string) ([]domain.OperationLog, error) {
	out := make([]domain.OperationLog, 0)
	for _, item := range s.items {
		if item.OperationResult == result {
			out = append(out, item)
		}
	}
	return out, nil
}
func (s operationLogStub) GetOperationLogsByTimeRange(start, end time.Time) ([]domain.OperationLog, error) {
	out := make([]domain.OperationLog, 0)
	for _, item := range s.items {
		if !item.OperationTime.Before(start) && !item.OperationTime.After(end) {
			out = append(out, item)
		}
	}
	return out, nil
}
func (operationLogStub) GetOperationLogsByUserId(string) ([]domain.OperationLog, error) {
	return nil, nil
}
func (operationLogStub) GetOperationResultsByPrefixGlobally(string) ([]string, error) {
	return nil, nil
}
func (operationLogStub) GetUserIdsByPrefixGlobally(string) ([]string, error) { return nil, nil }

func TestLogSearchRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	loginWhen, _ := time.Parse("2006-01-02T15:04:05", "2026-09-30T09:00:00")
	later := loginWhen.Add(48 * time.Hour)
	logout := loginWhen.Add(time.Hour)
	router := gin.New()
	NewLoginLogController(loginLogStub{items: []domain.LoginLog{
		{LogID: 1, Username: "driver", LoginTime: loginWhen, LogoutTime: &logout, LoginIP: "10.0.0.8", LoginLocation: "Shanghai", DeviceType: "Mobile", BrowserType: "Chrome"},
		{LogID: 2, Username: "admin", LoginTime: later, LoginIP: "10.1.1.9", LoginLocation: "Beijing", DeviceType: "Desktop", BrowserType: "Edge"},
	}}).RegisterRoutes(router)
	(&OperationLogController{Service: operationLogStub{items: []domain.OperationLog{
		{LogID: 3, OperationModule: "Appeal", OperationType: "UPDATE", Username: "driver", RequestURL: "/api/appeals/1", RequestMethod: "PUT", OperationResult: "Success", OperationTime: loginWhen},
		{LogID: 4, OperationModule: "Fine", OperationType: "CREATE", Username: "admin", RequestURL: "/api/fines", RequestMethod: "POST", OperationResult: "Failed", OperationTime: later},
	}}}).RegisterRoutes(router.Group(""))

	assertLogin := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.LoginLog
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s decode %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].LogID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}
	assertOperation := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.OperationLog
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s decode %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].LogID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}

	assertLogin("/api/logs/login/search/time-range?startTime=2026-09-30T00:00:00&endTime=2026-09-30T23:59:59", 1)
	assertLogin("/api/logs/login/search/ip?ip=10.0.0", 1)
	assertLogin("/api/logs/login/search/location?loginLocation=Beijing", 2)
	assertLogin("/api/logs/login/search/device-type?deviceType=Mobile", 1)
	assertLogin("/api/logs/login/search/browser-type?browserType=Edge", 2)
	assertOperation("/api/logs/operation/search/result?operationResult=Failed", 4)
	assertOperation("/api/logs/operation/search/module?module=Appeal", 3)
	assertOperation("/api/logs/operation/search/type?type=CREATE", 4)
	assertOperation("/api/logs/operation/search/username?username=driver", 3)
	assertOperation("/api/logs/operation/search/request-url?requestUrl=/api/fines", 4)
	assertOperation("/api/logs/operation/search/request-method?requestMethod=PUT", 3)
	assertOperation("/api/logs/operation/search/time-range?startTime=2026-09-30&endTime=2026-09-30", 3)
}
