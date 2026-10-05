package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestCacheClearMatchesFrontendContract(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("normalizedRoles", []string{"TRAFFIC_POLICE"})
		c.Next()
	})
	NewCacheController().RegisterRoutes(router)

	res := httptest.NewRecorder()
	router.ServeHTTP(res, httptest.NewRequest(http.MethodPost, "/api/cache/clear", nil))
	if res.Code != http.StatusNoContent {
		t.Fatalf("staff status=%d body=%s", res.Code, res.Body.String())
	}

	denied := gin.New()
	denied.Use(func(c *gin.Context) {
		c.Set("normalizedRoles", []string{"USER"})
		c.Next()
	})
	NewCacheController().RegisterRoutes(denied)
	res = httptest.NewRecorder()
	denied.ServeHTTP(res, httptest.NewRequest(http.MethodPost, "/api/cache/clear", nil))
	if res.Code != http.StatusForbidden {
		t.Fatalf("user status=%d", res.Code)
	}
}
