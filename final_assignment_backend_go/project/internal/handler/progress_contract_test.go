package handler

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type progressStub struct {
	items []domain.ProgressItem
}

func (s *progressStub) CreateProgress(item *domain.ProgressItem) (*domain.ProgressItem, error) {
	item.ID = len(s.items) + 1
	s.items = append(s.items, *item)
	return item, nil
}
func (s *progressStub) DeleteProgress(id int) error {
	return nil
}
func (s *progressStub) GetAllProgress() ([]domain.ProgressItem, error) { return s.items, nil }
func (s *progressStub) GetProgressByStatus(string) ([]domain.ProgressItem, error) {
	return s.items, nil
}
func (s *progressStub) GetProgressByTimeRange(time.Time, time.Time) ([]domain.ProgressItem, error) {
	return s.items, nil
}
func (s *progressStub) GetProgressByUsername(username string) ([]domain.ProgressItem, error) {
	out := make([]domain.ProgressItem, 0)
	for _, item := range s.items {
		if item.Username == username {
			out = append(out, item)
		}
	}
	return out, nil
}
func (s *progressStub) UpdateProgress(item *domain.ProgressItem) (*domain.ProgressItem, error) {
	for i := range s.items {
		if s.items[i].ID == item.ID {
			if item.Status != "" {
				s.items[i].Status = item.Status
			}
			if item.Title != "" {
				s.items[i].Title = item.Title
			}
			return &s.items[i], nil
		}
	}
	return nil, errNotVisible
}
func (s *progressStub) UpdateProgressStatus(id int, status string) (*domain.ProgressItem, error) {
	return s.UpdateProgress(&domain.ProgressItem{ID: id, Status: status})
}

func TestProgressRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	when, _ := time.Parse(time.RFC3339, "2026-09-30T10:00:00+08:00")
	stub := &progressStub{items: []domain.ProgressItem{
		{ID: 1, Title: "appeal", Status: "PENDING", Username: "driver", SubmitTime: when},
		{ID: 2, Title: "fine", Status: "Completed", Username: "other", SubmitTime: when.Add(48 * time.Hour)},
	}}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "driver")
		c.Set("normalizedRoles", []string{"USER"})
		c.Next()
	})
	NewProgressHandler(stub).RegisterRoutes(router)

	statusRes := httptest.NewRecorder()
	router.ServeHTTP(statusRes, httptest.NewRequest(http.MethodGet, "/api/progress/status?status=Pending", nil))
	if statusRes.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", statusRes.Code, statusRes.Body.String())
	}
	var listed []domain.ProgressItem
	if err := json.Unmarshal(statusRes.Body.Bytes(), &listed); err != nil {
		t.Fatal(err)
	}
	if len(listed) != 1 || listed[0].ID != 1 {
		t.Fatalf("status filter leaked or missed: %#v", listed)
	}

	body := bytes.NewBufferString(`{"businessType":"appeal","businessStatus":"Processing","submitTime":"2026-09-30T10:00:00Z"}`)
	update := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPut, "/api/progress/1", body)
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(update, req)
	if update.Code != http.StatusOK {
		t.Fatalf("update=%d body=%s", update.Code, update.Body.String())
	}
	var updated domain.ProgressItem
	if err := json.Unmarshal(update.Body.Bytes(), &updated); err != nil {
		t.Fatal(err)
	}
	if updated.Status != "Processing" || updated.Title != "appeal" {
		t.Fatalf("updated=%#v", updated)
	}

	got := httptest.NewRecorder()
	router.ServeHTTP(got, httptest.NewRequest(http.MethodGet, "/api/progress/1", nil))
	if got.Code != http.StatusOK {
		t.Fatalf("get=%d body=%s", got.Code, got.Body.String())
	}
}
