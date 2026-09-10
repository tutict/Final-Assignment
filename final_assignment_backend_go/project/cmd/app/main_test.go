package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"final_assignment_backend_go/project/internal/repo"
	"final_assignment_backend_go/project/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

const reactDevOrigin = "http://127.0.0.1:5173"

func TestRegisterRoutesDoesNotPanic(t *testing.T) {
	oldMode := gin.Mode()
	gin.SetMode(gin.TestMode)
	t.Cleanup(func() { gin.SetMode(oldMode) })

	router := gin.New()
	userService := service.NewUserManagementService(repo.NewUserManagementRepo(nil))

	registerRoutes(router, nil, userService, nil, nil)

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

func TestCorsPreflightAllowsReactLoginOrigin(t *testing.T) {
	router := gin.New()
	router.Use(devCorsMiddleware())
	router.POST("/api/auth/login", func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	req := httptest.NewRequest(http.MethodOptions, "/api/auth/login", nil)
	req.Header.Set("Origin", reactDevOrigin)
	req.Header.Set("Access-Control-Request-Method", http.MethodPost)
	req.Header.Set("Access-Control-Request-Headers", "content-type, authorization")
	res := httptest.NewRecorder()

	router.ServeHTTP(res, req)

	if res.Code != http.StatusNoContent {
		t.Fatalf("expected CORS preflight to return 204, got %d", res.Code)
	}
	if got := res.Header().Get("Access-Control-Allow-Origin"); got != reactDevOrigin {
		t.Fatalf("expected React origin to be allowed, got %q", got)
	}
	if got := res.Header().Get("Access-Control-Allow-Headers"); !strings.Contains(got, "Authorization") {
		t.Fatalf("expected Authorization to be allowed, got %q", got)
	}
}

func TestEventBusWebSocketAcceptsReactOrigin(t *testing.T) {
	router := gin.New()
	router.Use(devCorsMiddleware())
	registerEventBusRoute(router)
	server := httptest.NewServer(router)
	t.Cleanup(server.Close)

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/eventbus/websocket"
	headers := http.Header{}
	headers.Set("Origin", reactDevOrigin)
	conn, resp, err := websocket.DefaultDialer.Dial(wsURL, headers)
	if resp != nil && resp.Body != nil {
		defer resp.Body.Close()
	}
	if err != nil {
		status := 0
		if resp != nil {
			status = resp.StatusCode
		}
		t.Fatalf("expected WebSocket upgrade to succeed, status=%d err=%v", status, err)
	}
	t.Cleanup(func() { _ = conn.Close() })
}
