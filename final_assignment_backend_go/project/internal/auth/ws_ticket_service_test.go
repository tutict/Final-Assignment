package auth

import (
	"testing"
	"time"
)

func TestNewWsTicketService(t *testing.T) {
	service := NewWsTicketService(30 * time.Second)
	if service == nil {
		t.Fatal("NewWsTicketService returned nil")
	}

	if service.ttl != 30*time.Second {
		t.Errorf("TTL = %v, want 30s", service.ttl)
	}
}

func TestWsTicketService_Issue(t *testing.T) {
	service := NewWsTicketService(30 * time.Second)

	ticket, err := service.Issue("testuser", []string{"DRIVER"})
	if err != nil {
		t.Fatalf("Issue() error = %v", err)
	}

	if ticket.Ticket == "" {
		t.Error("Ticket ID is empty")
	}

	if ticket.Username != "testuser" {
		t.Errorf("Username = %s, want testuser", ticket.Username)
	}

	if len(ticket.Roles) != 1 || ticket.Roles[0] != "DRIVER" {
		t.Errorf("Roles = %v, want [DRIVER]", ticket.Roles)
	}

	if ticket.ExpiresAt.Before(time.Now()) {
		t.Error("Ticket already expired")
	}
}

func TestWsTicketService_Consume(t *testing.T) {
	service := NewWsTicketService(30 * time.Second)

	// Issue a ticket
	issued, _ := service.Issue("testuser", []string{"ADMIN"})

	// Consume it
	ticket, ok := service.Consume(issued.Ticket)
	if !ok {
		t.Fatal("Failed to consume valid ticket")
	}

	if ticket.Username != "testuser" {
		t.Errorf("Username = %s, want testuser", ticket.Username)
	}

	// Try to consume again (should fail - single use)
	_, ok = service.Consume(issued.Ticket)
	if ok {
		t.Error("Should not be able to consume ticket twice")
	}
}

func TestWsTicketService_Validate(t *testing.T) {
	service := NewWsTicketService(30 * time.Second)

	// Issue a ticket
	issued, _ := service.Issue("testuser", []string{"DRIVER"})

	// Validate (should not consume)
	ticket, ok := service.Validate(issued.Ticket)
	if !ok {
		t.Fatal("Failed to validate valid ticket")
	}

	if ticket.Username != "testuser" {
		t.Errorf("Username = %s, want testuser", ticket.Username)
	}

	// Validate again (should still work)
	_, ok = service.Validate(issued.Ticket)
	if !ok {
		t.Error("Validate should not consume ticket")
	}

	// Now consume it
	_, ok = service.Consume(issued.Ticket)
	if !ok {
		t.Error("Failed to consume after validate")
	}

	// Validate after consume (should fail)
	_, ok = service.Validate(issued.Ticket)
	if ok {
		t.Error("Should not validate consumed ticket")
	}
}

func TestWsTicketService_ExpiredTicket(t *testing.T) {
	service := NewWsTicketService(100 * time.Millisecond)

	// Issue a ticket
	issued, _ := service.Issue("testuser", []string{"DRIVER"})

	// Wait for expiration
	time.Sleep(150 * time.Millisecond)

	// Try to consume expired ticket
	_, ok := service.Consume(issued.Ticket)
	if ok {
		t.Error("Should not be able to consume expired ticket")
	}
}

func TestWsTicketService_InvalidTicket(t *testing.T) {
	service := NewWsTicketService(30 * time.Second)

	// Try to consume non-existent ticket
	_, ok := service.Consume("invalid-ticket-id")
	if ok {
		t.Error("Should not be able to consume invalid ticket")
	}

	// Try to validate non-existent ticket
	_, ok = service.Validate("invalid-ticket-id")
	if ok {
		t.Error("Should not validate invalid ticket")
	}
}

func TestWsTicketService_Count(t *testing.T) {
	service := NewWsTicketService(30 * time.Second)

	if service.Count() != 0 {
		t.Errorf("Initial count = %d, want 0", service.Count())
	}

	// Issue tickets
	service.Issue("user1", []string{"DRIVER"})
	service.Issue("user2", []string{"ADMIN"})
	service.Issue("user3", []string{"SUPER_ADMIN"})

	if service.Count() != 3 {
		t.Errorf("Count after issuing = %d, want 3", service.Count())
	}

	// Consume one
	tickets := []string{}
	service.tickets.Range(func(key, value interface{}) bool {
		tickets = append(tickets, key.(string))
		return true
	})

	if len(tickets) > 0 {
		service.Consume(tickets[0])
	}

	if service.Count() != 2 {
		t.Errorf("Count after consuming = %d, want 2", service.Count())
	}
}

func TestWsTicketService_Clear(t *testing.T) {
	service := NewWsTicketService(30 * time.Second)

	// Issue tickets
	service.Issue("user1", []string{"DRIVER"})
	service.Issue("user2", []string{"ADMIN"})

	if service.Count() != 2 {
		t.Errorf("Count before clear = %d, want 2", service.Count())
	}

	// Clear all
	service.Clear()

	if service.Count() != 0 {
		t.Errorf("Count after clear = %d, want 0", service.Count())
	}
}

func TestWsTicketService_CleanupExpiredTickets(t *testing.T) {
	service := NewWsTicketService(100 * time.Millisecond)

	// Issue tickets
	service.Issue("user1", []string{"DRIVER"})
	service.Issue("user2", []string{"ADMIN"})

	if service.Count() != 2 {
		t.Errorf("Count = %d, want 2", service.Count())
	}

	// Wait for expiration and cleanup
	time.Sleep(200 * time.Millisecond)

	// Manually trigger cleanup by validating
	service.tickets.Range(func(key, value interface{}) bool {
		service.Validate(key.(string))
		return true
	})

	// Expired tickets should be removed
	if service.Count() != 0 {
		t.Errorf("Count after cleanup = %d, want 0", service.Count())
	}
}

func TestWsTicketService_MultipleRoles(t *testing.T) {
	service := NewWsTicketService(30 * time.Second)

	roles := []string{"DRIVER", "ADMIN", "SUPER_ADMIN"}
	ticket, _ := service.Issue("multiuser", roles)

	if len(ticket.Roles) != 3 {
		t.Errorf("Roles count = %d, want 3", len(ticket.Roles))
	}

	consumed, ok := service.Consume(ticket.Ticket)
	if !ok {
		t.Fatal("Failed to consume ticket")
	}

	if len(consumed.Roles) != 3 {
		t.Errorf("Consumed roles count = %d, want 3", len(consumed.Roles))
	}
}
