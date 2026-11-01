package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

type chatActionsEnvelope struct {
	Success bool               `json:"success"`
	Data    chatActionResponse `json:"data"`
}

type chatActionValuePayload struct {
	Source  string            `json:"source"`
	Role    string            `json:"role"`
	Prefill map[string]string `json:"prefill"`
}

func performGetChatActions(t *testing.T, roles []string, message string) (*httptest.ResponseRecorder, chatActionsEnvelope) {
	t.Helper()
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/api/ai/chat/actions", func(c *gin.Context) {
		if roles != nil {
			c.Set("normalizedRoles", roles)
		}
		(&AiChatHandler{}).GetChatActions(c)
	})

	target := "/api/ai/chat/actions"
	if message != "" {
		target += "?message=" + url.QueryEscape(message)
	}
	req := httptest.NewRequest(http.MethodGet, target, nil)
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, req)

	var envelope chatActionsEnvelope
	if recorder.Code == http.StatusOK {
		if err := json.Unmarshal(recorder.Body.Bytes(), &envelope); err != nil {
			t.Fatalf("decode response: %v (%s)", err, recorder.Body.String())
		}
	}
	return recorder, envelope
}

func TestGetChatActions_DriverRuleAndPrefill(t *testing.T) {
	recorder, envelope := performGetChatActions(
		t,
		[]string{"USER"},
		"我要申诉，车牌京A12345，手机13800138000，身份证110101199003077777",
	)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200 (%s)", recorder.Code, recorder.Body.String())
	}
	if !envelope.Success || envelope.Data.Answer == "" {
		t.Fatalf("unexpected envelope: %+v", envelope)
	}
	if len(envelope.Data.Actions) != 1 {
		t.Fatalf("actions = %d, want 1", len(envelope.Data.Actions))
	}
	action := envelope.Data.Actions[0]
	if action.Type != "NAVIGATE" || action.Target != "/userAppeal" {
		t.Fatalf("unexpected action: %+v", action)
	}

	var value chatActionValuePayload
	if err := json.Unmarshal([]byte(action.Value), &value); err != nil {
		t.Fatalf("decode action value: %v (%s)", err, action.Value)
	}
	if value.Source != "chat_action_rule" || value.Role != "driver" {
		t.Fatalf("unexpected value payload: %+v", value)
	}
	if value.Prefill["licensePlate"] != "京A12345" {
		t.Errorf("licensePlate = %q", value.Prefill["licensePlate"])
	}
	if value.Prefill["phone"] != "13800138000" {
		t.Errorf("phone = %q", value.Prefill["phone"])
	}
	if value.Prefill["idCard"] != "110101199003077777" {
		t.Errorf("idCard = %q", value.Prefill["idCard"])
	}
}

func TestGetChatActions_AdminRuleOverridesDriverTarget(t *testing.T) {
	const message = "帮我打开申诉办理页面"
	_, adminEnvelope := performGetChatActions(t, []string{"ADMIN"}, message)
	if len(adminEnvelope.Data.Actions) != 1 || adminEnvelope.Data.Actions[0].Target != "/appealManagement" {
		t.Fatalf("admin action = %+v", adminEnvelope.Data.Actions)
	}

	_, driverEnvelope := performGetChatActions(t, []string{"USER"}, message)
	if len(driverEnvelope.Data.Actions) != 1 || driverEnvelope.Data.Actions[0].Target != "/userAppeal" {
		t.Fatalf("driver action = %+v", driverEnvelope.Data.Actions)
	}
}

func TestGetChatActions_SuperAdminUsesGovernanceRules(t *testing.T) {
	_, envelope := performGetChatActions(t, []string{"SUPER_ADMIN"}, "打开用户权限管理")
	if len(envelope.Data.Actions) != 1 {
		t.Fatalf("actions = %d, want 1", len(envelope.Data.Actions))
	}
	if envelope.Data.Actions[0].Target != "/admin/userManagementPage" {
		t.Fatalf("target = %q", envelope.Data.Actions[0].Target)
	}

	var value chatActionValuePayload
	if err := json.Unmarshal([]byte(envelope.Data.Actions[0].Value), &value); err != nil {
		t.Fatalf("decode action value: %v", err)
	}
	if value.Role != "super_admin" {
		t.Fatalf("role = %q", value.Role)
	}
}

func TestGetChatActions_NoRuleReturnsGuidedAnswer(t *testing.T) {
	recorder, envelope := performGetChatActions(t, []string{"USER"}, "今天天气怎么样")
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", recorder.Code)
	}
	if len(envelope.Data.Actions) != 0 {
		t.Fatalf("actions = %d, want 0", len(envelope.Data.Actions))
	}
	if envelope.Data.Answer != unsupportedChatActionAnswer {
		t.Fatalf("answer = %q", envelope.Data.Answer)
	}
}

func TestGetChatActions_RequiresMessage(t *testing.T) {
	recorder, _ := performGetChatActions(t, []string{"USER"}, "")
	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", recorder.Code)
	}
	if !strings.Contains(recorder.Body.String(), "INVALID_MESSAGE") {
		t.Fatalf("body = %s", recorder.Body.String())
	}
}
