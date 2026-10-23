package handler

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type stubWorkflowService struct {
	appealCalls  int
	appealReason string
}

func (s *stubWorkflowService) TriggerOffenseEvent(int64, string) (*domain.OffenseInformation, error) {
	return nil, nil
}

func (s *stubWorkflowService) TriggerPaymentEvent(int64, string, string) (*domain.PaymentRecord, error) {
	return nil, nil
}

func (s *stubWorkflowService) TriggerAppealEvent(appealID int64, event string, idempotencyKey string, reason string) (*domain.AppealManagement, error) {
	s.appealCalls++
	s.appealReason = reason
	return &domain.AppealManagement{
		AppealID:        int(appealID),
		ProcessStatus:   "Rejected",
		RejectionReason: reason,
	}, nil
}

func workflowRouter(service *stubWorkflowService) *gin.Engine {
	return workflowRouterWithRole(service, "ADMIN")
}

func workflowRouterWithRole(service *stubWorkflowService, role string) *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("role", role)
		c.Set("normalizedRoles", []string{role})
		c.Next()
	})
	NewWorkflowController(service).RegisterRoutes(router.Group("/api"))
	return router
}

func TestAppealWorkflowRejectsUserRole(t *testing.T) {
	service := &stubWorkflowService{}
	req := httptest.NewRequest(http.MethodPost, "/api/workflow/appeals/1/events/REJECT",
		strings.NewReader(`{"reason":"证据不足"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", "key-user")
	res := httptest.NewRecorder()

	workflowRouterWithRole(service, "USER").ServeHTTP(res, req)

	if res.Code != http.StatusForbidden {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if service.appealCalls != 0 {
		t.Fatal("USER must not reach the workflow service")
	}
}

func TestAppealWorkflowPassesTrimmedReason(t *testing.T) {
	service := &stubWorkflowService{}
	req := httptest.NewRequest(http.MethodPost, "/api/workflow/appeals/1/events/REJECT",
		strings.NewReader(`{"reason":"  证据不足  "}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", "key-reason")
	res := httptest.NewRecorder()

	workflowRouter(service).ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if service.appealReason != "证据不足" {
		t.Fatalf("reason=%q want 证据不足", service.appealReason)
	}
}

func TestAppealWorkflowAllowsMissingBody(t *testing.T) {
	service := &stubWorkflowService{}
	req := httptest.NewRequest(http.MethodPost, "/api/workflow/appeals/1/events/APPROVE", nil)
	req.Header.Set("Idempotency-Key", "key-no-body")
	res := httptest.NewRecorder()

	workflowRouter(service).ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if service.appealReason != "" {
		t.Fatalf("reason=%q want empty", service.appealReason)
	}
}

func TestAppealWorkflowRejectsMalformedBody(t *testing.T) {
	service := &stubWorkflowService{}
	req := httptest.NewRequest(http.MethodPost, "/api/workflow/appeals/1/events/REJECT",
		strings.NewReader(`{"reason":`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", "key-malformed")
	res := httptest.NewRecorder()

	workflowRouter(service).ServeHTTP(res, req)

	if res.Code != http.StatusBadRequest {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if service.appealCalls != 0 {
		t.Fatal("malformed body must not reach the workflow service")
	}
}

func TestAppealWorkflowRejectsOverlongReason(t *testing.T) {
	service := &stubWorkflowService{}
	req := httptest.NewRequest(http.MethodPost, "/api/workflow/appeals/1/events/REJECT",
		strings.NewReader(`{"reason":"`+strings.Repeat("a", 501)+`"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", "key-too-long")
	res := httptest.NewRecorder()

	workflowRouter(service).ServeHTTP(res, req)

	if res.Code != http.StatusBadRequest {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if service.appealCalls != 0 {
		t.Fatal("overlong reason must not reach the workflow service")
	}
}
