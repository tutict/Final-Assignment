package handler

import (
	"net/http"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/auth"

	"github.com/gin-gonic/gin"
)

// WsTicketHandler handles WebSocket ticket issuance
type WsTicketHandler struct {
	wsTicketService *auth.WsTicketService
}

// NewWsTicketHandler creates a new WebSocket ticket handler
func NewWsTicketHandler(wsTicketService *auth.WsTicketService) *WsTicketHandler {
	return &WsTicketHandler{
		wsTicketService: wsTicketService,
	}
}

// IssueTicketRequest represents the request to issue a ticket
type IssueTicketRequest struct {
	Username string   `json:"username" binding:"required"`
	Roles    []string `json:"roles" binding:"required"`
}

// IssueTicketResponse represents the response with ticket details
type IssueTicketResponse struct {
	Ticket    string    `json:"ticket"`
	ExpiresAt time.Time `json:"expiresAt"`
	ExpiresIn int       `json:"expiresIn"` // seconds
}

// IssueTicket handles POST /api/ws-ticket
func (wth *WsTicketHandler) IssueTicket(c *gin.Context) {
	var req IssueTicketRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request",
			"details": err.Error(),
		})
		return
	}

	// Validate roles
	if len(req.Roles) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "At least one role is required",
		})
		return
	}

	// Issue ticket
	ticket, err := wth.wsTicketService.Issue(req.Username, req.Roles)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to issue ticket",
		})
		return
	}

	expiresIn := int(time.Until(ticket.ExpiresAt).Seconds())

	c.JSON(http.StatusOK, IssueTicketResponse{
		Ticket:    ticket.Ticket,
		ExpiresAt: ticket.ExpiresAt,
		ExpiresIn: expiresIn,
	})
}

// IssueTicketFromAuth issues a ticket based on authentication context
// This version extracts username and roles from JWT token
func (wth *WsTicketHandler) IssueTicketFromAuth(c *gin.Context) {
	// Extract JWT token from Authorization header
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Authorization header required",
		})
		return
	}

	// Remove "Bearer " prefix
	token := strings.TrimPrefix(authHeader, "Bearer ")
	if token == authHeader {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Invalid authorization format",
		})
		return
	}

	// Get username and roles from context (set by auth middleware)
	username, exists := c.Get("username")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Username not found in context",
		})
		return
	}

	rolesInterface, exists := c.Get("roles")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Roles not found in context",
		})
		return
	}

	// Convert roles to []string
	roles, ok := rolesInterface.([]string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Invalid roles format",
		})
		return
	}

	// Issue ticket
	ticket, err := wth.wsTicketService.Issue(username.(string), roles)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to issue ticket",
		})
		return
	}

	expiresIn := int(time.Until(ticket.ExpiresAt).Seconds())

	c.JSON(http.StatusOK, IssueTicketResponse{
		Ticket:    ticket.Ticket,
		ExpiresAt: ticket.ExpiresAt,
		ExpiresIn: expiresIn,
	})
}

// ValidateTicket handles ticket validation (for debugging)
func (wth *WsTicketHandler) ValidateTicket(c *gin.Context) {
	ticketID := c.Query("ticket")
	if ticketID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Ticket parameter required",
		})
		return
	}

	ticket, valid := wth.wsTicketService.Validate(ticketID)
	if !valid {
		c.JSON(http.StatusNotFound, gin.H{
			"valid": false,
			"error": "Ticket not found or expired",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"valid":     true,
		"username":  ticket.Username,
		"roles":     ticket.Roles,
		"expiresAt": ticket.ExpiresAt,
		"expiresIn": int(time.Until(ticket.ExpiresAt).Seconds()),
	})
}

// GetStats returns statistics about active tickets (for monitoring)
func (wth *WsTicketHandler) GetStats(c *gin.Context) {
	count := wth.wsTicketService.Count()

	c.JSON(http.StatusOK, gin.H{
		"activeTickets": count,
	})
}
