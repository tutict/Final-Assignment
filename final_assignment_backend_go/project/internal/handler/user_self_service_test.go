package handler

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type recordingUsers struct {
	user  domain.UserManagement
	saved *domain.UserManagement
}

func (r *recordingUsers) CheckAndInsertIdempotency(_ string, user *domain.UserManagement, _ string) error {
	copy := *user
	r.saved = &copy
	return nil
}
func (r *recordingUsers) DeleteUserByID(string) error       { return nil }
func (r *recordingUsers) DeleteUserByUsername(string) error { return nil }
func (r *recordingUsers) GetAllUsers() ([]domain.UserManagement, error) {
	return nil, nil
}
func (r *recordingUsers) GetPhoneNumbersByPrefixGlobally(string) ([]string, error) { return nil, nil }
func (r *recordingUsers) GetStatusesByPrefixGlobally(string) ([]string, error)     { return nil, nil }
func (r *recordingUsers) GetUserByID(string) (*domain.UserManagement, error) {
	copy := r.user
	return &copy, nil
}
func (r *recordingUsers) GetUserById(int) (*domain.UserManagement, error) {
	copy := r.user
	return &copy, nil
}
func (r *recordingUsers) GetUserByUsername(string) (*domain.UserManagement, error) {
	copy := r.user
	return &copy, nil
}
func (r *recordingUsers) GetUsernamesByPrefixGlobally(string) ([]string, error) { return nil, nil }
func (r *recordingUsers) GetUsersByRole(string) ([]domain.UserManagement, error) {
	return nil, nil
}
func (r *recordingUsers) GetUsersByStatus(string) ([]domain.UserManagement, error) {
	return nil, nil
}
func (r *recordingUsers) IsUsernameExists(string) bool            { return false }
func (r *recordingUsers) UpdateUser(*domain.UserManagement) error { return nil }
func (r *recordingUsers) UpdateUserByID(_ string, user *domain.UserManagement, _ string) error {
	copy := *user
	r.saved = &copy
	return nil
}

func TestUpdateCurrentUserKeepsPasswordAndAcceptsPhoneAlias(t *testing.T) {
	gin.SetMode(gin.TestMode)
	users := &recordingUsers{user: domain.UserManagement{
		UserID:        7,
		Username:      "driver",
		Password:      "$2hashed",
		RealName:      "旧名字",
		ContactNumber: "13800000000",
		Email:         "old@example.com",
		Status:        "Active",
	}}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "driver")
		c.Next()
	})
	ctrl := NewUserManagementController(users)
	api := router.Group("/api")
	ctrl.RegisterRoutes(api)

	req := httptest.NewRequest(http.MethodPut, "/api/users/me", strings.NewReader(`{"realName":"新名字","phoneNumber":"138****0000","email":"new@example.com","password":"should-not-apply","status":"Disabled"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", "profile-1")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)
	if res.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if users.saved == nil {
		t.Fatal("profile was not saved")
	}
	if users.saved.Password != "$2hashed" || users.saved.Status != "Active" || users.saved.Username != "driver" {
		t.Fatalf("self-service overwrote protected fields: %#v", users.saved)
	}
	if users.saved.RealName != "新名字" || users.saved.Email != "new@example.com" {
		t.Fatalf("profile fields not merged: %#v", users.saved)
	}
	if users.saved.ContactNumber != "13800000000" {
		t.Fatalf("masked phone was stored: %s", users.saved.ContactNumber)
	}
}

func TestUpdatePasswordAcceptsPlainText(t *testing.T) {
	gin.SetMode(gin.TestMode)
	users := &recordingUsers{user: domain.UserManagement{UserID: 7, Username: "driver", Password: "$2hashed"}}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "driver")
		c.Next()
	})
	ctrl := NewUserManagementController(users)
	api := router.Group("/api")
	ctrl.RegisterRoutes(api)

	req := httptest.NewRequest(http.MethodPut, "/api/users/me/password", strings.NewReader("new-password"))
	req.Header.Set("Content-Type", "text/plain; charset=utf-8")
	req.Header.Set("Idempotency-Key", "pwd-1")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)
	if res.Code != http.StatusNoContent {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if users.saved == nil || users.saved.Password != "new-password" || users.saved.Username != "driver" {
		t.Fatalf("password update did not keep the account: %#v", users.saved)
	}
}

func TestUpdateUserMergesPartialPayload(t *testing.T) {
	gin.SetMode(gin.TestMode)
	users := &recordingUsers{user: domain.UserManagement{
		UserID:   9,
		Username: "admin",
		Password: "$2hashed",
		Email:    "admin@example.com",
		Status:   "Active",
	}}
	router := gin.New()
	ctrl := NewUserManagementController(users)
	api := router.Group("/api")
	ctrl.RegisterRoutes(api)

	req := httptest.NewRequest(http.MethodPut, "/api/users/9", strings.NewReader(`{"email":"next@example.com","phoneNumber":"13900001111"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", "user-9")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)
	if res.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", res.Code, res.Body.String())
	}
	if users.saved.Password != "$2hashed" || users.saved.Username != "admin" || users.saved.Email != "next@example.com" || users.saved.ContactNumber != "13900001111" {
		t.Fatalf("partial update mismatch: %#v", users.saved)
	}
}
