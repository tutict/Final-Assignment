package handler

import (
	"encoding/json"
	"net/http"
	"strings"
	"net/http/httptest"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

func TestAppealReviewRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	when, _ := time.Parse("2006-01-02T15:04:05", "2026-09-30T08:00:00")
	later := when.Add(48 * time.Hour)
	router := gin.New()
	NewAppealHandler(stubAppealService{reviews: []domain.AppealReview{
		{ReviewID: 1, AppealID: 9, ReviewLevel: "FIRST", Reviewer: "Li", ReviewerDept: "Traffic", ReviewTime: when},
		{ReviewID: 2, AppealID: 9, ReviewLevel: "SECOND", Reviewer: "Zhao", ReviewerDept: "Legal", ReviewTime: later},
	}}).RegisterSearchRoutes(router.Group("/api/appeals"))

	assertOne := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.AppealReview
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].ReviewID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}

	assertOne("/api/appeals/reviews/search/reviewer?reviewer=Zhao", 2)
	assertOne("/api/appeals/reviews/search/reviewer-dept?reviewerDept=Traffic", 1)
	assertOne("/api/appeals/reviews/search/time-range?startTime=2026-09-30&endTime=2026-09-30", 1)

	count := httptest.NewRecorder()
	router.ServeHTTP(count, httptest.NewRequest(http.MethodGet, "/api/appeals/reviews/count?level=FIRST", nil))
	if count.Code != http.StatusOK {
		t.Fatalf("count status=%d body=%s", count.Code, count.Body.String())
	}
	var payload map[string]int
	if err := json.Unmarshal(count.Body.Bytes(), &payload); err != nil {
		t.Fatal(err)
	}
	if payload["count"] != 1 {
		t.Fatalf("count=%v", payload)
	}

	one := httptest.NewRecorder()
	router.ServeHTTP(one, httptest.NewRequest(http.MethodGet, "/api/appeals/reviews/1", nil))
	if one.Code != http.StatusOK {
		t.Fatalf("detail status=%d body=%s", one.Code, one.Body.String())
	}
}

func TestAppealReviewWriteRoutes(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var updated domain.AppealReview
	deleted := 0
	router := gin.New()
	NewAppealHandler(stubAppealService{updated: &updated, deleted: &deleted}).RegisterSearchRoutes(router.Group("/api/appeals"))

	body := strings.NewReader(`{"reviewLevel":"SECOND","reviewer":"Zhao","reviewResult":"APPROVED","reviewOpinion":"ok"}`)
	req := httptest.NewRequest(http.MethodPut, "/api/appeals/reviews/8", body)
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)
	if res.Code != http.StatusOK {
		t.Fatalf("update status=%d body=%s", res.Code, res.Body.String())
	}
	if updated.ReviewID != 8 || updated.Reviewer != "Zhao" || updated.ReviewResult != "APPROVED" {
		t.Fatalf("updated=%#v", updated)
	}

	delRes := httptest.NewRecorder()
	router.ServeHTTP(delRes, httptest.NewRequest(http.MethodDelete, "/api/appeals/reviews/8", nil))
	if delRes.Code != http.StatusNoContent {
		t.Fatalf("delete status=%d body=%s", delRes.Code, delRes.Body.String())
	}
	if deleted != 8 {
		t.Fatalf("deleted=%d", deleted)
	}
}
