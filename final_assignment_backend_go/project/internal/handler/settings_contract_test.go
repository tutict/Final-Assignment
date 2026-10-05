package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type settingsStub struct {
	rows []domain.SysSetting
}

func (settingsStub) CheckAndInsertIdempotency(string, *domain.SystemSettings) error { return nil }
func (settingsStub) GetCopyrightInfo() string                                       { return "" }
func (settingsStub) GetDateFormat() string                                          { return "" }
func (settingsStub) GetEmailAccount() string                                        { return "" }
func (settingsStub) GetEmailPassword() string                                       { return "" }
func (settingsStub) GetLoginTimeout() int                                           { return 0 }
func (settingsStub) GetPageSize() int                                               { return 0 }
func (settingsStub) GetSessionTimeout() int                                         { return 0 }
func (settingsStub) GetSmtpServer() string                                          { return "" }
func (settingsStub) GetStoragePath() string                                         { return "" }
func (settingsStub) GetSystemDescription() string                                   { return "" }
func (settingsStub) GetSystemName() string                                          { return "" }
func (settingsStub) GetSystemSettings() (*domain.SystemSettings, error) {
	return &domain.SystemSettings{SystemName: "aggregate"}, nil
}
func (settingsStub) GetSystemVersion() string { return "" }
func (s settingsStub) ListSysSettings() ([]domain.SysSetting, error) {
	return s.rows, nil
}

func TestSettingsRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	NewSystemSettingsController(settingsStub{rows: []domain.SysSetting{
		{SettingID: 1, SettingKey: "system.name", SettingValue: "Traffic", SettingType: "STRING", Category: "GENERAL", IsEditable: true},
		{SettingID: 2, SettingKey: "mail.password", SettingValue: "secret", SettingType: "SECRET", Category: "MAIL", IsEncrypted: true},
	}}).RegisterRoutes(router)

	list := httptest.NewRecorder()
	router.ServeHTTP(list, httptest.NewRequest(http.MethodGet, "/api/system/settings", nil))
	if list.Code != http.StatusOK {
		t.Fatalf("list status=%d body=%s", list.Code, list.Body.String())
	}
	var rows []domain.SysSetting
	if err := json.Unmarshal(list.Body.Bytes(), &rows); err != nil {
		t.Fatalf("list decode: %v body=%s", err, list.Body.String())
	}
	if len(rows) != 2 {
		t.Fatalf("expected setting rows, got %#v", rows)
	}

	legacy := httptest.NewRecorder()
	router.ServeHTTP(legacy, httptest.NewRequest(http.MethodGet, "/api/systemSettings", nil))
	if legacy.Code != http.StatusOK {
		t.Fatalf("legacy status=%d body=%s", legacy.Code, legacy.Body.String())
	}
	var aggregate domain.SystemSettings
	if err := json.Unmarshal(legacy.Body.Bytes(), &aggregate); err != nil {
		t.Fatalf("legacy decode: %v body=%s", err, legacy.Body.String())
	}
	if aggregate.SystemName != "aggregate" {
		t.Fatalf("legacy aggregate=%#v", aggregate)
	}

	key := httptest.NewRecorder()
	router.ServeHTTP(key, httptest.NewRequest(http.MethodGet, "/api/system/settings/search/key/prefix?settingKey=mail.", nil))
	if key.Code != http.StatusOK {
		t.Fatalf("key status=%d body=%s", key.Code, key.Body.String())
	}
	var matched []domain.SysSetting
	if err := json.Unmarshal(key.Body.Bytes(), &matched); err != nil {
		t.Fatal(err)
	}
	if len(matched) != 1 || matched[0].SettingID != 2 {
		t.Fatalf("key search=%#v", matched)
	}

	encrypted := httptest.NewRecorder()
	router.ServeHTTP(encrypted, httptest.NewRequest(http.MethodGet, "/api/system/settings/search/encrypted?isEncrypted=true", nil))
	if encrypted.Code != http.StatusOK {
		t.Fatalf("encrypted status=%d body=%s", encrypted.Code, encrypted.Body.String())
	}
	if err := json.Unmarshal(encrypted.Body.Bytes(), &matched); err != nil {
		t.Fatal(err)
	}
	if len(matched) != 1 || matched[0].SettingID != 2 {
		t.Fatalf("encrypted search=%#v", matched)
	}
}
