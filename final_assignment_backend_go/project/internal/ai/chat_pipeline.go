package ai

import (
	"context"
	"fmt"

	"final_assignment_backend_go/project/internal/service"
)

// ChatPipeline orchestrates the complete AI chat flow:
// RAG retrieval → prompt assembly → streaming response
type ChatPipeline struct {
	promptAssembler *PromptAssembler
	ragQueryService service.AiChatRagQuerier
	aiProvider      service.AiProvider
	config          service.AiChatConfig
}

// NewChatPipeline creates a new ChatPipeline with all dependencies
func NewChatPipeline(
	ragQueryService service.AiChatRagQuerier,
	aiProvider service.AiProvider,
	config service.AiChatConfig,
) (*ChatPipeline, error) {
	promptAssembler, err := NewPromptAssembler()
	if err != nil {
		return nil, fmt.Errorf("failed to create prompt assembler: %w", err)
	}

	// Normalize config
	normalizedConfig := normalizeAiChatConfig(config)

	return &ChatPipeline{
		promptAssembler: promptAssembler,
		ragQueryService: ragQueryService,
		aiProvider:      aiProvider,
		config:          normalizedConfig,
	}, nil
}

// Stream orchestrates the complete chat pipeline and returns a stream of events
func (cp *ChatPipeline) Stream(
	ctx context.Context,
	req service.AiChatStreamRequest,
) (<-chan service.AiChatStreamEvent, error) {
	// 1. Extract metadata
	metadata := req.Metadata
	if metadata == nil {
		metadata = make(map[string]any)
	}

	// 2. Check if RAG is enabled
	var ragResults []service.RagRetrievalResult
	if cp.isRagEnabled(metadata) && cp.ragQueryService != nil {
		ragRequest := cp.buildRagRequest(req.Message, metadata)
		ragResponse, err := cp.ragQueryService.Query(ctx, ragRequest)
		if err != nil {
			// Log error but don't fail - continue without RAG context
			fmt.Printf("[ChatPipeline] RAG query failed: %v\n", err)
		} else {
			ragResults = ragResponse.Results
		}
	}

	// 3. Get agent constraints (for now, use default from config)
	agentConstraints := cp.getAgentConstraints(metadata)

	// 4. Extract conversation window
	conversationWindow := extractConversationWindow(metadata)

	// 5. Assemble final prompt
	finalPrompt, err := cp.promptAssembler.Assemble(
		req.Message,
		conversationWindow,
		ragResults,
		agentConstraints,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to assemble prompt: %w", err)
	}

	// 6. Stream from AI provider
	return cp.streamFromProvider(ctx, finalPrompt, req.SessionKey, metadata)
}

// isRagEnabled checks if RAG retrieval is enabled for this request
func (cp *ChatPipeline) isRagEnabled(metadata map[string]any) bool {
	if ragEnabled, ok := metadata["ragEnabled"].(bool); ok {
		return ragEnabled
	}
	// Default to true if not specified
	return true
}

// buildRagRequest constructs a RAG query request from metadata
func (cp *ChatPipeline) buildRagRequest(message string, metadata map[string]any) service.RagQueryRequest {
	defaultTopK := 10
	req := service.RagQueryRequest{
		Query: message,
		TopK:  &defaultTopK, // Default
	}

	// Extract topK
	if topK, ok := metadata["topK"].(int); ok && topK > 0 {
		req.TopK = &topK
	} else if ragTopK, ok := metadata["ragTopK"].(int); ok && ragTopK > 0 {
		req.TopK = &ragTopK
	} else if topKFloat, ok := metadata["topK"].(float64); ok && topKFloat > 0 {
		topKInt := int(topKFloat)
		req.TopK = &topKInt
	}

	// Extract userId
	if userId, ok := metadata["userId"].(string); ok {
		req.UserID = userId
	}

	// Extract roles
	if roles, ok := metadata["roles"].([]string); ok {
		req.Roles = roles
	} else if rolesAny, ok := metadata["roles"].([]any); ok {
		req.Roles = make([]string, 0, len(rolesAny))
		for _, r := range rolesAny {
			if roleStr, ok := r.(string); ok {
				req.Roles = append(req.Roles, roleStr)
			}
		}
	}

	// Extract department
	if department, ok := metadata["department"].(string); ok {
		req.Department = department
	}

	return req
}

// getAgentConstraints returns agent constraints based on user role
func (cp *ChatPipeline) getAgentConstraints(metadata map[string]any) string {
	// For now, use default constraints from config
	// Phase 2 will add role resolver and file-based policies
	roles := extractRoles(metadata)

	// Simple role detection (will be enhanced in Phase 2)
	for _, role := range roles {
		switch role {
		case "SUPER_ADMIN":
			return cp.config.SuperAdminAgentConstraints
		case "ADMIN":
			return cp.config.AdminAgentConstraints
		case "DRIVER":
			return cp.config.DriverAgentConstraints
		}
	}

	// Default to driver constraints
	return cp.config.DriverAgentConstraints
}

// extractRoles extracts user roles from metadata
func extractRoles(metadata map[string]any) []string {
	if roles, ok := metadata["roles"].([]string); ok {
		return roles
	}
	if rolesAny, ok := metadata["roles"].([]any); ok {
		result := make([]string, 0, len(rolesAny))
		for _, r := range rolesAny {
			if roleStr, ok := r.(string); ok {
				result = append(result, roleStr)
			}
		}
		return result
	}
	return []string{"DRIVER"} // Default role
}

// extractConversationWindow extracts conversation history from metadata
func extractConversationWindow(metadata map[string]any) []string {
	var result []string

	// Try to extract from metadata
	if window, ok := metadata["conversationWindow"].([]string); ok {
		return window
	}

	if windowAny, ok := metadata["conversationWindow"].([]any); ok {
		for _, item := range windowAny {
			if itemMap, ok := item.(map[string]any); ok {
				// Handle structured format: {role: "user", content: "..."}
				role := "message"
				if r, ok := itemMap["role"].(string); ok && r != "" {
					role = r
				}
				if content, ok := itemMap["content"].(string); ok && content != "" {
					result = append(result, fmt.Sprintf("%s: %s", role, content))
				}
			} else if itemStr, ok := item.(string); ok {
				result = append(result, itemStr)
			}
		}
	}

	return result
}

// streamFromProvider wraps the AI provider stream with ChatStreamEvent format
func (cp *ChatPipeline) streamFromProvider(
	ctx context.Context,
	prompt string,
	sessionKey string,
	metadata map[string]any,
) (<-chan service.AiChatStreamEvent, error) {
	// Get token stream from provider
	tokenChan, errChan := cp.aiProvider.Stream(ctx, prompt, metadata, cp.config)

	// Create output channel
	outChan := make(chan service.AiChatStreamEvent, 10)

	// Launch goroutine to convert tokens to events
	go func() {
		defer close(outChan)

		for {
			select {
			case <-ctx.Done():
				outChan <- service.AiChatStreamEvent{
					Type:       service.ChatStreamEventTypeError,
					SessionKey: sessionKey,
					Payload:    "Request cancelled",
				}
				return
			case err, ok := <-errChan:
				if !ok {
					// Error channel closed, check if we should continue reading tokens
					continue
				}
				if err != nil {
					outChan <- service.AiChatStreamEvent{
						Type:       service.ChatStreamEventTypeError,
						SessionKey: sessionKey,
						Payload:    err.Error(),
					}
					return
				}
			case token, ok := <-tokenChan:
				if !ok {
					// Stream finished normally
					outChan <- service.AiChatStreamEvent{
						Type:       service.ChatStreamEventTypeDone,
						SessionKey: sessionKey,
					}
					return
				}

				// Send token event
				tokenText := token.Text
				outChan <- service.AiChatStreamEvent{
					Type:       service.ChatStreamEventTypeToken,
					SessionKey: sessionKey,
					Token:      &tokenText,
					Payload:    token,
				}

				// Check if this is the last token
				if token.Finished {
					outChan <- service.AiChatStreamEvent{
						Type:       service.ChatStreamEventTypeDone,
						SessionKey: sessionKey,
					}
					return
				}
			}
		}
	}()

	return outChan, nil
}

// normalizeAiChatConfig ensures all config fields have valid values
func normalizeAiChatConfig(config service.AiChatConfig) service.AiChatConfig {
	defaults := service.DefaultAiChatConfig()

	if config.PromptContextTokenBudget <= 0 {
		config.PromptContextTokenBudget = defaults.PromptContextTokenBudget
	}
	if config.KeepaliveInterval <= 0 {
		config.KeepaliveInterval = defaults.KeepaliveInterval
	}
	if config.DriverAgentConstraints == "" {
		config.DriverAgentConstraints = defaults.DriverAgentConstraints
	}
	if config.AdminAgentConstraints == "" {
		config.AdminAgentConstraints = defaults.AdminAgentConstraints
	}
	if config.SuperAdminAgentConstraints == "" {
		config.SuperAdminAgentConstraints = defaults.SuperAdminAgentConstraints
	}

	return config
}
