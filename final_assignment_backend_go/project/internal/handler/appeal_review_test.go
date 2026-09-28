package handler

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestCreateReviewRequiresIdempotencyKey(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("normalizedRoles", []string{"ADMIN"})
		c.Next()
	})
	router.POST("/api/appeals/:id/reviews", NewAppealHandler(stubAppealService{}).CreateReview)

	missing := httptest.NewRequest(http.MethodPost, "/api/appeals/4/reviews", strings.NewReader(`{"reviewLevel":"FIRST","reviewer":"ann","reviewResult":"UPHELD"}`))
	missing.Header.Set("Content-Type", "application/json")
	missingRec := httptest.NewRecorder()
	router.ServeHTTP(missingRec, missing)
	if missingRec.Code != http.StatusBadRequest {
		t.Fatalf("missing key status=%d body=%s", missingRec.Code, missingRec.Body.String())
	}

	present := httptest.NewRequest(http.MethodPost, "/api/appeals/4/reviews", strings.NewReader(`{"reviewLevel":"FIRST","reviewer":"ann","reviewResult":"UPHELD"}`))
	present.Header.Set("Content-Type", "application/json")
	present.Header.Set("Idempotency-Key", "review-1")
	presentRec := httptest.NewRecorder()
	router.ServeHTTP(presentRec, present)
	if presentRec.Code != http.StatusCreated {
		t.Fatalf("create status=%d body=%s", presentRec.Code, presentRec.Body.String())
	}
}
