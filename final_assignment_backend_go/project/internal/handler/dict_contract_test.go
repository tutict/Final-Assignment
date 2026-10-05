package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type dictStub struct {
	rows []domain.SysDict
}

func (s dictStub) ListSysDicts() ([]domain.SysDict, error) { return s.rows, nil }

func TestDictSearchRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	parent := 4
	router := gin.New()
	NewSystemSettingsController(settingsStub{}).WithDicts(dictStub{rows: []domain.SysDict{
		{DictID: 1, ParentID: &parent, DictType: "payment_status", DictCode: "UNPAID", DictLabel: "未支付", Status: "Active", IsDefault: true},
		{DictID: 2, DictType: "payment_status", DictCode: "PAID", DictLabel: "已支付", Status: "Disabled"},
		{DictID: 3, DictType: "appeal_type", DictCode: "OTHER", DictLabel: "其他", Status: "Active"},
	}}).RegisterRoutes(router)

	assertOne := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.SysDict
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].DictID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}

	assertOne("/api/system/settings/dicts/search/type?dictType=appeal_type", 3)
	assertOne("/api/system/settings/dicts/search/code?dictCode=UN", 1)
	assertOne("/api/system/settings/dicts/search/label/prefix?dictLabel="+url.QueryEscape("未"), 1)
	assertOne("/api/system/settings/dicts/search/label/fuzzy?dictLabel="+url.QueryEscape("其他"), 3)
	assertOne("/api/system/settings/dicts/search/parent?parentId=4", 1)
	assertOne("/api/system/settings/dicts/search/default?isDefault=true", 1)
	assertOne("/api/system/settings/dicts/search/status?status=Disabled", 2)

	fuzzy := httptest.NewRecorder()
	router.ServeHTTP(fuzzy, httptest.NewRequest(http.MethodGet, "/api/system/settings/dicts/search/label/fuzzy?dictLabel="+url.QueryEscape("支付"), nil))
	if fuzzy.Code != http.StatusOK {
		t.Fatalf("fuzzy status=%d body=%s", fuzzy.Code, fuzzy.Body.String())
	}
	var fuzzyRows []domain.SysDict
	if err := json.Unmarshal(fuzzy.Body.Bytes(), &fuzzyRows); err != nil {
		t.Fatal(err)
	}
	if len(fuzzyRows) != 2 {
		t.Fatalf("fuzzy got %d rows", len(fuzzyRows))
	}
}
