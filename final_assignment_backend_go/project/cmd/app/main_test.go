package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"final_assignment_backend_go/project/internal/repo"
	"final_assignment_backend_go/project/internal/service"

	"github.com/gin-gonic/gin"
)

func TestRegisterRoutesDoesNotPanic(t *testing.T) {
	oldMode := gin.Mode()
	gin.SetMode(gin.TestMode)
	t.Cleanup(func() { gin.SetMode(oldMode) })

	router := gin.New()
	userService := service.NewUserManagementService(repo.NewUserManagementRepo(nil))

	registerRoutes(router, nil, userService)

	if len(router.Routes()) == 0 {
		t.Fatal("expected routes to be registered")
	}
}

func TestAccessPolicyRequiresAdminForAdminPaths(t *testing.T) {
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("role", "USER")
		c.Next()
	})
	router.Use(accessPolicy())
	router.GET("/api/users", func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	req := httptest.NewRequest(http.MethodGet, "/api/users", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusForbidden {
		t.Fatalf("expected forbidden for non-admin user, got %d", res.Code)
	}
}

func TestAccessPolicyAllowsCurrentUserPath(t *testing.T) {
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("role", "USER")
		c.Next()
	})
	router.Use(accessPolicy())
	router.GET("/api/users/me", func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	req := httptest.NewRequest(http.MethodGet, "/api/users/me", nil)
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusNoContent {
		t.Fatalf("expected current user path to be allowed, got %d", res.Code)
	}
}
