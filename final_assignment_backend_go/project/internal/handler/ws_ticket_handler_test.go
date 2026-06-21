package handler

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/auth"

	"github.com/gin-gonic/gin"
)

func TestWsTicketHandler_IssueTicket(t *testing.T) {
	gin.SetMode(gin.TestMode)

	service := auth.NewWsTicketService(30 * time.Second)
	handler := NewWsTicketHandler(service)

	tests := []struct {
		name       string
		request    IssueTicketRequest
		wantStatus int
		wantError  bool
	}{
		{
			name: "valid request",
			request: IssueTicketRequest{
				Username: "testuser",
				Roles:    []string{"DRIVER"},
			},
			wantStatus: http.StatusOK,
			wantError:  false,
		},
		{
			name: "multiple roles",
			request: IssueTicketRequest{
				Username: "adminuser",
				Roles:    []string{"ADMIN", "DRIVER"},
			},
			wantStatus: http.StatusOK,
			wantError:  false,
		},
		{
			name: "missing username",
			request: IssueTicketRequest{
				Username: "",
				Roles:    []string{"DRIVER"},
			},
			wantStatus: http.StatusBadRequest,
			wantError:  true,
		},
		{
			name: "missing roles",
			request: IssueTicketRequest{
				Username: "testuser",
				Roles:    []string{},
			},
			wantStatus: http.StatusBadRequest,
			wantError:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			body, _ := json.Marshal(tt.request)
			c.Request = httptest.NewRequest("POST", "/api/ws-ticket", bytes.NewReader(body))
			c.Request.Header.Set("Content-Type", "application/json")

			handler.IssueTicket(c)

			if w.Code != tt.wantStatus {
				t.Errorf("Status = %d, want %d", w.Code, tt.wantStatus)
			}

			if !tt.wantError {
				var response IssueTicketResponse
				if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
					t.Fatalf("Failed to parse response: %v", err)
				}

				if response.Ticket == "" {
					t.Error("Ticket is empty")
				}

				if response.ExpiresIn <= 0 {
					t.Errorf("ExpiresIn = %d, want > 0", response.ExpiresIn)
				}

				if response.ExpiresAt.Before(time.Now()) {
					t.Error("ExpiresAt is in the past")
				}
			}
		})
	}
}

func TestWsTicketHandler_IssueTicketFromAuth(t *testing.T) {
	gin.SetMode(gin.TestMode)

	service := auth.NewWsTicketService(30 * time.Second)
	handler := NewWsTicketHandler(service)

	tests := []struct {
		name         string
		authHeader   string
		setContext   bool
		username     string
		roles        []string
		wantStatus   int
		wantError    bool
	}{
		{
			name:       "valid auth",
			authHeader: "Bearer test-token",
			setContext: true,
			username:   "testuser",
			roles:      []string{"DRIVER"},
			wantStatus: http.StatusOK,
			wantError:  false,
		},
		{
			name:       "missing authorization header",
			authHeader: "",
			setContext: false,
			wantStatus: http.StatusUnauthorized,
			wantError:  true,
		},
		{
			name:       "invalid authorization format",
			authHeader: "InvalidFormat token",
			setContext: false,
			wantStatus: http.StatusUnauthorized,
			wantError:  true,
		},
		{
			name:       "missing username in context",
			authHeader: "Bearer test-token",
			setContext: false,
			wantStatus: http.StatusUnauthorized,
			wantError:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			c.Request = httptest.NewRequest("POST", "/api/ws-ticket/auth", nil)
			if tt.authHeader != "" {
				c.Request.Header.Set("Authorization", tt.authHeader)
			}

			if tt.setContext {
				c.Set("username", tt.username)
				c.Set("roles", tt.roles)
			}

			handler.IssueTicketFromAuth(c)

			if w.Code != tt.wantStatus {
				t.Errorf("Status = %d, want %d", w.Code, tt.wantStatus)
			}

			if !tt.wantError {
				var response IssueTicketResponse
				if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
					t.Fatalf("Failed to parse response: %v", err)
				}

				if response.Ticket == "" {
					t.Error("Ticket is empty")
				}
			}
		})
	}
}

func TestWsTicketHandler_ValidateTicket(t *testing.T) {
	gin.SetMode(gin.TestMode)

	service := auth.NewWsTicketService(30 * time.Second)
	handler := NewWsTicketHandler(service)

	// Issue a ticket first
	ticket, _ := service.Issue("testuser", []string{"DRIVER"})

	tests := []struct {
		name       string
		ticketID   string
		wantStatus int
		wantValid  bool
	}{
		{
			name:       "valid ticket",
			ticketID:   ticket.Ticket,
			wantStatus: http.StatusOK,
			wantValid:  true,
		},
		{
			name:       "invalid ticket",
			ticketID:   "invalid-ticket-id",
			wantStatus: http.StatusNotFound,
			wantValid:  false,
		},
		{
			name:       "missing ticket parameter",
			ticketID:   "",
			wantStatus: http.StatusBadRequest,
			wantValid:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			url := "/api/ws-ticket/validate"
			if tt.ticketID != "" {
				url += "?ticket=" + tt.ticketID
			}
			c.Request = httptest.NewRequest("GET", url, nil)

			handler.ValidateTicket(c)

			if w.Code != tt.wantStatus {
				t.Errorf("Status = %d, want %d", w.Code, tt.wantStatus)
			}

			var response map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &response)

			if valid, ok := response["valid"].(bool); ok {
				if valid != tt.wantValid {
					t.Errorf("Valid = %v, want %v", valid, tt.wantValid)
				}
			}
		})
	}
}

func TestWsTicketHandler_GetStats(t *testing.T) {
	gin.SetMode(gin.TestMode)

	service := auth.NewWsTicketService(30 * time.Second)
	handler := NewWsTicketHandler(service)

	// Issue some tickets
	service.Issue("user1", []string{"DRIVER"})
	service.Issue("user2", []string{"ADMIN"})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/api/ws-ticket/stats", nil)

	handler.GetStats(c)

	if w.Code != http.StatusOK {
		t.Errorf("Status = %d, want %d", w.Code, http.StatusOK)
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("Failed to parse response: %v", err)
	}

	if count, ok := response["activeTickets"].(float64); ok {
		if int(count) != 2 {
			t.Errorf("ActiveTickets = %d, want 2", int(count))
		}
	} else {
		t.Error("activeTickets not found in response")
	}
}

func TestWsTicketHandler_ExpiredTicket(t *testing.T) {
	gin.SetMode(gin.TestMode)

	service := auth.NewWsTicketService(100 * time.Millisecond)
	handler := NewWsTicketHandler(service)

	// Issue a ticket
	ticket, _ := service.Issue("testuser", []string{"DRIVER"})

	// Wait for expiration
	time.Sleep(150 * time.Millisecond)

	// Try to validate expired ticket
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/api/ws-ticket/validate?ticket="+ticket.Ticket, nil)

	handler.ValidateTicket(c)

	if w.Code != http.StatusNotFound {
		t.Errorf("Status = %d, want %d (expired ticket should be not found)", w.Code, http.StatusNotFound)
	}
}
