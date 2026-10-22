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
	keys  map[string]int
}

func (s *progressStub) CreateProgress(item *domain.ProgressItem, key string) (*domain.ProgressItem, error) {
	item.ID = len(s.items) + 1
	s.items = append(s.items, *item)
	if key != "" {
		if s.keys == nil {
			s.keys = make(map[string]int)
		}
		s.keys[key] = item.ID
	}
	return item, nil
}

func (s *progressStub) FindProgressByIdempotencyKey(key string) (*domain.ProgressItem, error) {
	id, ok := s.keys[key]
	if !ok {
		return nil, nil
	}
	for i := range s.items {
		if s.items[i].ID == id {
			return &s.items[i], nil
		}
	}
	return nil, nil
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

	got := httptest.NewRecorder()
	router.ServeHTTP(got, httptest.NewRequest(http.MethodGet, "/api/progress/1", nil))
	if got.Code != http.StatusOK {
		t.Fatalf("get=%d body=%s", got.Code, got.Body.String())
	}

	peek := httptest.NewRecorder()
	router.ServeHTTP(peek, httptest.NewRequest(http.MethodGet, "/api/progress/by-username?username=other", nil))
	if peek.Code != http.StatusForbidden {
		t.Fatalf("driver peek other user = %d, want 403", peek.Code)
	}
}

func TestProgressAdminCanUpdateAndDelete(t *testing.T) {
	gin.SetMode(gin.TestMode)
	stub := &progressStub{items: []domain.ProgressItem{
		{ID: 1, Title: "appeal", Status: "Pending", Username: "driver", SubmitTime: time.Now()},
		{ID: 2, Title: "fine", Status: "Pending", Username: "other", SubmitTime: time.Now()},
	}}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "admin")
		c.Set("normalizedRoles", []string{"SUPER_ADMIN"})
		c.Next()
	})
	NewProgressHandler(stub).RegisterRoutes(router)

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

	statusRes := httptest.NewRecorder()
	router.ServeHTTP(statusRes, httptest.NewRequest(http.MethodPut, "/api/progress/2/status?newStatus=Archived", nil))
	if statusRes.Code != http.StatusOK {
		t.Fatalf("status update=%d body=%s", statusRes.Code, statusRes.Body.String())
	}

	del := httptest.NewRecorder()
	router.ServeHTTP(del, httptest.NewRequest(http.MethodDelete, "/api/progress/2", nil))
	if del.Code != http.StatusNoContent {
		t.Fatalf("delete=%d body=%s", del.Code, del.Body.String())
	}
}

func TestProgressCreateReplayHonorsIdempotencyKey(t *testing.T) {
	gin.SetMode(gin.TestMode)
	stub := &progressStub{}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "admin")
		c.Set("normalizedRoles", []string{"SUPER_ADMIN"})
		c.Next()
	})
	NewProgressHandler(stub).RegisterRoutes(router)

	body := `{"title":"replay","status":"Pending"}`
	create := func() *httptest.ResponseRecorder {
		req := httptest.NewRequest(http.MethodPost, "/api/progress", bytes.NewBufferString(body))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Idempotency-Key", "progress-replay-1")
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)
		return rec
	}

	if rec := create(); rec.Code != http.StatusCreated {
		t.Fatalf("first create = %d body=%s", rec.Code, rec.Body.String())
	}
	if rec := create(); rec.Code != http.StatusAlreadyReported {
		t.Fatalf("replay = %d body=%s", rec.Code, rec.Body.String())
	}
	if len(stub.items) != 1 {
		t.Fatalf("replay must not create a new row, got %d", len(stub.items))
	}
}

func TestProgressDriverCannotWrite(t *testing.T) {
	gin.SetMode(gin.TestMode)
	stub := &progressStub{items: []domain.ProgressItem{
		{ID: 1, Title: "appeal", Status: "Pending", Username: "driver", SubmitTime: time.Now()},
		{ID: 2, Title: "fine", Status: "Pending", Username: "other", SubmitTime: time.Now()},
	}}
	router := gin.New()
	router.Use(func(c *gin.Context) {
		c.Set("username", "driver")
		c.Set("normalizedRoles", []string{"USER"})
		c.Next()
	})
	NewProgressHandler(stub).RegisterRoutes(router)

	statusRes := httptest.NewRecorder()
	router.ServeHTTP(statusRes, httptest.NewRequest(http.MethodPut, "/api/progress/1/status?newStatus=Archived", nil))
	if statusRes.Code != http.StatusForbidden {
		t.Fatalf("status update = %d, want 403", statusRes.Code)
	}

	del := httptest.NewRecorder()
	router.ServeHTTP(del, httptest.NewRequest(http.MethodDelete, "/api/progress/2", nil))
	if del.Code != http.StatusForbidden {
		t.Fatalf("delete = %d, want 403", del.Code)
	}

	update := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPut, "/api/progress/1", bytes.NewBufferString(`{"status":"Archived"}`))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(update, req)
	if update.Code != http.StatusForbidden {
		t.Fatalf("update = %d, want 403", update.Code)
	}

	own := httptest.NewRecorder()
	router.ServeHTTP(own, httptest.NewRequest(http.MethodGet, "/api/progress/by-username?username=driver", nil))
	if own.Code != http.StatusOK {
		t.Fatalf("driver own list = %d body=%s", own.Code, own.Body.String())
	}
	var listed []domain.ProgressItem
	if err := json.Unmarshal(own.Body.Bytes(), &listed); err != nil {
		t.Fatal(err)
	}
	if len(listed) != 1 || listed[0].Username != "driver" {
		t.Fatalf("driver own list = %#v", listed)
	}

	create := httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/api/progress", bytes.NewBufferString(`{"title":"self","username":"other"}`))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(create, req)
	if create.Code != http.StatusCreated {
		t.Fatalf("driver create = %d body=%s", create.Code, create.Body.String())
	}
	if len(stub.items) != 3 || stub.items[2].Username != "driver" {
		t.Fatalf("driver create must bind JWT owner, got %#v", stub.items)
	}
}
