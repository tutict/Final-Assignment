package auth

import (
	"sync"
	"time"

	"github.com/google/uuid"
)

// WsTicket represents a WebSocket authentication ticket
type WsTicket struct {
	Ticket    string    `json:"ticket"`
	Username  string    `json:"username"`
	Roles     []string  `json:"roles"`
	ExpiresAt time.Time `json:"expiresAt"`
	CreatedAt time.Time `json:"createdAt"`
}

// WsTicketService manages WebSocket authentication tickets
type WsTicketService struct {
	tickets sync.Map // ticket UUID -> WsTicket
	mu      sync.Mutex
	ttl     time.Duration
}

// NewWsTicketService creates a new WebSocket ticket service
func NewWsTicketService(ttl time.Duration) *WsTicketService {
	if ttl <= 0 {
		ttl = 30 * time.Second // Default 30 seconds
	}

	service := &WsTicketService{
		ttl: ttl,
	}

	// Start background cleanup goroutine
	go service.cleanupExpiredTickets()

	return service
}

// Issue creates and stores a new ticket
func (wts *WsTicketService) Issue(username string, roles []string) (*WsTicket, error) {
	ticket := &WsTicket{
		Ticket:    uuid.New().String(),
		Username:  username,
		Roles:     roles,
		ExpiresAt: time.Now().Add(wts.ttl),
		CreatedAt: time.Now(),
	}

	wts.tickets.Store(ticket.Ticket, ticket)
	return ticket, nil
}

// Consume validates and removes a ticket (single use)
func (wts *WsTicketService) Consume(ticketID string) (*WsTicket, bool) {
	val, ok := wts.tickets.LoadAndDelete(ticketID)
	if !ok {
		return nil, false
	}

	ticket := val.(*WsTicket)

	// Check if expired
	if time.Now().After(ticket.ExpiresAt) {
		return nil, false
	}

	return ticket, true
}

// Validate checks if a ticket is valid without consuming it
func (wts *WsTicketService) Validate(ticketID string) (*WsTicket, bool) {
	val, ok := wts.tickets.Load(ticketID)
	if !ok {
		return nil, false
	}

	ticket := val.(*WsTicket)

	// Check if expired
	if time.Now().After(ticket.ExpiresAt) {
		wts.tickets.Delete(ticketID)
		return nil, false
	}

	return ticket, true
}

// cleanupExpiredTickets runs periodically to remove expired tickets
func (wts *WsTicketService) cleanupExpiredTickets() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		now := time.Now()
		wts.tickets.Range(func(key, value interface{}) bool {
			ticket := value.(*WsTicket)
			if now.After(ticket.ExpiresAt) {
				wts.tickets.Delete(key)
			}
			return true
		})
	}
}

// Count returns the number of active tickets
func (wts *WsTicketService) Count() int {
	count := 0
	wts.tickets.Range(func(key, value interface{}) bool {
		count++
		return true
	})
	return count
}

// Clear removes all tickets (for testing)
func (wts *WsTicketService) Clear() {
	wts.tickets.Range(func(key, value interface{}) bool {
		wts.tickets.Delete(key)
		return true
	})
}
