package reliability

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestLedgerReconcileRequiresAdminAndReportsCount(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	calls := 0
	router.POST("/actuator/ledgerReconcile", LedgerReconcile(func() (int, error) {
		calls++
		return 2, nil
	}))

	denied := httptest.NewRequest(http.MethodPost, "/actuator/ledgerReconcile", nil)
	deniedRec := httptest.NewRecorder()
	router.ServeHTTP(deniedRec, denied)
	if deniedRec.Code != http.StatusForbidden {
		t.Fatalf("anonymous status=%d", deniedRec.Code)
	}

	allowed := httptest.NewRequest(http.MethodPost, "/actuator/ledgerReconcile", nil)
	allowedRec := httptest.NewRecorder()
	router.Use(func(c *gin.Context) {})
	router = gin.New()
	router.POST("/actuator/ledgerReconcile", func(c *gin.Context) {
		c.Set("normalizedRoles", []string{"ADMIN"})
		c.Next()
	}, LedgerReconcile(func() (int, error) {
		calls++
		return 2, nil
	}))
	router.ServeHTTP(allowedRec, allowed)
	if allowedRec.Code != http.StatusOK {
		t.Fatalf("admin status=%d body=%s", allowedRec.Code, allowedRec.Body.String())
	}
	var body map[string]int
	if err := json.Unmarshal(allowedRec.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if body["updated"] != 2 || calls != 1 {
		t.Fatalf("updated=%d calls=%d", body["updated"], calls)
	}
}
