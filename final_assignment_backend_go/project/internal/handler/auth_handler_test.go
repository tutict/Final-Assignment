package handler

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"

	"github.com/gin-gonic/gin"
)

type fakeAuthService struct {
	registerStatus string
	registerErr    error
	loginResult    map[string]any
	loginErr       error
}

func (f fakeAuthService) GetAllUsers() ([]domain.UserManagement, error) { return nil, nil }

func (f fakeAuthService) Login(service.LoginRequest) (map[string]any, error) {
	if f.loginErr != nil {
		return nil, f.loginErr
	}
	if f.loginResult != nil {
		return f.loginResult, nil
	}
	return nil, nil
}

func (f fakeAuthService) Refresh(string) (map[string]any, error) { return nil, nil }

func (f fakeAuthService) RegisterUser(service.RegisterRequest) (string, error) {
	if f.registerErr != nil {
		return "", f.registerErr
	}
	return f.registerStatus, nil
}

func (f fakeAuthService) Logout(string, string) error { return nil }

func (f fakeAuthService) GetCurrentUserProfile(string) (map[string]any, error) { return nil, nil }

func TestRegisterUserNormalizesSuccessStatusForFrontend(t *testing.T) {
	oldMode := gin.Mode()
	gin.SetMode(gin.TestMode)
	t.Cleanup(func() { gin.SetMode(oldMode) })

	router := gin.New()
	router.POST("/api/auth/register", NewAuthHandler(fakeAuthService{registerStatus: "registered"}).RegisterUser)

	body := bytes.NewBufferString(`{"username":"new-user@example.com","password":"123456"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/register", body)
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()

	router.ServeHTTP(res, req)

	if res.Code != http.StatusCreated {
		t.Fatalf("expected HTTP 201, got %d body=%s", res.Code, res.Body.String())
	}

	var response map[string]string
	if err := json.Unmarshal(res.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if got := response["status"]; got != service.RegisterStatusCreated {
		t.Fatalf("expected register status %q for frontend contract, got %q", service.RegisterStatusCreated, got)
	}
}

func TestRegisterUserReturnsConflictOnServiceError(t *testing.T) {
	oldMode := gin.Mode()
	gin.SetMode(gin.TestMode)
	t.Cleanup(func() { gin.SetMode(oldMode) })

	router := gin.New()
	router.POST("/api/auth/register", NewAuthHandler(fakeAuthService{registerErr: errors.New("username already exists")}).RegisterUser)

	body := bytes.NewBufferString(`{"username":"existing@example.com","password":"123456"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/register", body)
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()

	router.ServeHTTP(res, req)

	if res.Code != http.StatusConflict {
		t.Fatalf("expected HTTP 409, got %d body=%s", res.Code, res.Body.String())
	}
}

func TestLoginReturnsFullAuthContractForFrontends(t *testing.T) {
	oldMode := gin.Mode()
	gin.SetMode(gin.TestMode)
	t.Cleanup(func() { gin.SetMode(oldMode) })

	router := gin.New()
	router.POST("/api/auth/login", NewAuthHandler(fakeAuthService{loginResult: map[string]any{
		"jwtToken":     "jwt-value",
		"accessToken":  "jwt-value",
		"refreshToken": "refresh-value",
		"username":     "admin",
		"roles":        []string{"ADMIN"},
	}}).Login)

	body := bytes.NewBufferString(`{"username":"admin","password":"admin123"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", body)
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d body=%s", res.Code, res.Body.String())
	}
	var response map[string]any
	if err := json.Unmarshal(res.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	for _, key := range []string{"jwtToken", "accessToken", "refreshToken", "username"} {
		if response[key] == nil || response[key] == "" {
			t.Fatalf("expected %s in login payload, got %#v", key, response)
		}
	}
}

