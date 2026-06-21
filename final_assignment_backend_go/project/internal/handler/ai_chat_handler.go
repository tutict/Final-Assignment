package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/ai"
	"final_assignment_backend_go/project/internal/service"
)

// AiChatHandler handles AI chat streaming requests
type AiChatHandler struct {
	chatPipeline *ai.ChatPipeline
}

// NewAiChatHandler creates a new AiChatHandler
func NewAiChatHandler(chatPipeline *ai.ChatPipeline) *AiChatHandler {
	return &AiChatHandler{
		chatPipeline: chatPipeline,
	}
}

// StreamChat handles POST /api/ai/chat/stream
// Returns Server-Sent Events (SSE) stream
func (h *AiChatHandler) StreamChat(c *gin.Context) {
	// Parse request body
	var req service.AiChatStreamRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request format: " + err.Error(),
		})
		return
	}

	// Validate request
	if req.Message == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Message is required",
		})
		return
	}

	// Set SSE headers
	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("X-Accel-Buffering", "no") // Disable nginx buffering

	// Create context with timeout
	ctx, cancel := context.WithTimeout(c.Request.Context(), 2*time.Minute)
	defer cancel()

	// Get event stream from chat pipeline
	eventChan, err := h.chatPipeline.Stream(ctx, req)
	if err != nil {
		// Send error event
		h.writeSSE(c.Writer, "error", map[string]any{
			"error": err.Error(),
		})
		return
	}

	// Send initial session event
	h.writeSSE(c.Writer, "session", map[string]any{
		"sessionKey": req.SessionKey,
		"timestamp":  time.Now().Format(time.RFC3339),
	})
	c.Writer.Flush()

	// Stream events
	flusher, ok := c.Writer.(http.Flusher)
	if !ok {
		h.writeSSE(c.Writer, "error", map[string]any{
			"error": "Streaming not supported",
		})
		return
	}

	for event := range eventChan {
		// Convert event to SSE format
		h.writeSSE(c.Writer, "data", h.eventToMap(event))
		flusher.Flush()

		// Stop on done or error
		if event.Type == service.ChatStreamEventTypeDone || event.Type == service.ChatStreamEventTypeError {
			break
		}
	}
}

// writeSSE writes a Server-Sent Event to the response writer
func (h *AiChatHandler) writeSSE(w io.Writer, eventType string, data any) {
	// Marshal data to JSON
	jsonData, err := json.Marshal(data)
	if err != nil {
		jsonData = []byte(fmt.Sprintf(`{"error":"Failed to marshal data: %s"}`, err.Error()))
	}

	// Write SSE format: data: {json}\n\n
	fmt.Fprintf(w, "data: %s\n\n", jsonData)
}

// eventToMap converts AiChatStreamEvent to a map for JSON serialization
func (h *AiChatHandler) eventToMap(event service.AiChatStreamEvent) map[string]any {
	result := map[string]any{
		"type": event.Type,
	}

	if event.SessionKey != "" {
		result["sessionKey"] = event.SessionKey
	}

	if event.MessageID != "" {
		result["messageId"] = event.MessageID
	}

	if event.Token != nil {
		result["token"] = *event.Token
	}

	if event.Payload != nil {
		result["payload"] = event.Payload
	}

	if !event.Timestamp.IsZero() {
		result["timestamp"] = event.Timestamp.Format(time.RFC3339)
	} else {
		result["timestamp"] = time.Now().Format(time.RFC3339)
	}

	return result
}

// RegisterAiChatRoutes registers AI chat routes with the gin router
func RegisterAiChatRoutes(router *gin.Engine, handler *AiChatHandler) {
	api := router.Group("/api")
	{
		ai := api.Group("/ai")
		{
			ai.POST("/chat/stream", handler.StreamChat)
		}
	}
}
