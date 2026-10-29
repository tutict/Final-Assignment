package ai

import (
	"context"
	"fmt"
	"sync/atomic"
	"time"

	"final_assignment_backend_go/project/internal/ai/agent"
	"final_assignment_backend_go/project/internal/ai/guardrail"
	aisvc "final_assignment_backend_go/project/internal/service/ai"
	ragsvc "final_assignment_backend_go/project/internal/service/rag"
)

// ChatPipeline orchestrates the complete AI chat flow:
// RAG retrieval → prompt assembly → streaming response
type ChatPipeline struct {
	promptAssembler *PromptAssembler
	ragQueryService aisvc.AiChatRagQuerier
	aiProvider      aisvc.AiProvider
	config          aisvc.AiChatConfig
	agentRuntime    *agent.Runtime
	guardrail       *guardrail.Stage
}

var messageSequence atomic.Uint64

func newMessageID() string {
	return fmt.Sprintf("msg-%d-%d", time.Now().UnixNano(), messageSequence.Add(1))
}

// NewChatPipeline creates a new ChatPipeline with all dependencies
func NewChatPipeline(
	ragQueryService aisvc.AiChatRagQuerier,
	aiProvider aisvc.AiProvider,
	config aisvc.AiChatConfig,
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

func (cp *ChatPipeline) SetAgent(runtime *agent.Runtime) {
	cp.agentRuntime = runtime
}

func (cp *ChatPipeline) Agent() *agent.Runtime {
	return cp.agentRuntime
}

// SetGuardrail installs the answer-layer guardrail. Without it the pipeline streams as before.
func (cp *ChatPipeline) SetGuardrail(stage *guardrail.Stage) {
	cp.guardrail = stage
}

// Stream orchestrates the complete chat pipeline and returns a stream of events
func (cp *ChatPipeline) Stream(
	ctx context.Context,
	req aisvc.AiChatStreamRequest,
) (<-chan aisvc.AiChatStreamEvent, error) {
	// 1. Extract metadata
	metadata := req.Metadata
	if metadata == nil {
		metadata = make(map[string]any)
	}

	// 2. Check if RAG is enabled
	ragEnabled := cp.isRagEnabled(metadata)
	var ragResults []ragsvc.RagRetrievalResult
	if ragEnabled && cp.ragQueryService != nil {
		ragRequest, ragAccess := cp.buildRagRequest(req.Message, metadata)
		ragResponse, err := cp.ragQueryService.Query(ctx, ragRequest, ragAccess)
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

	// 5. Assemble final prompt; keep the sources that actually fit in the context
	var (
		finalPrompt string
		usedSources []ragsvc.RagRetrievalResult
		err         error
	)
	if ragEnabled {
		finalPrompt, usedSources, err = cp.promptAssembler.AssembleWithSources(
			req.Message,
			conversationWindow,
			ragResults,
			agentConstraints,
		)
	} else {
		finalPrompt, err = cp.promptAssembler.Assemble(
			req.Message,
			conversationWindow,
			nil,
			agentConstraints,
		)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to assemble prompt: %w", err)
	}

	// One message identity per SSE stream, including the citation-repair attempt.
	messageID := newMessageID()

	var events <-chan aisvc.AiChatStreamEvent
	if cp.agentRuntime != nil {
		agentEvents := cp.agentRuntime.Execute(req.Message, cp.agentContext(req.SessionKey, metadata))
		if len(agentEvents) > 0 {
			out := make(chan aisvc.AiChatStreamEvent, len(agentEvents)+8)
			go func() {
				defer close(out)
				for _, event := range agentEvents {
					out <- aisvc.AiChatStreamEvent{
						Type:       event.Type,
						SessionKey: event.SessionKey,
						MessageID:  messageID,
						Token:      event.Token,
						Payload:    event.Payload,
						Timestamp:  event.Timestamp,
					}
				}
				providerChan, err := cp.streamFromProvider(ctx, finalPrompt, req.SessionKey, messageID, metadata)
				if err != nil {
					out <- aisvc.AiChatStreamEvent{
						Type:       aisvc.ChatStreamEventTypeError,
						SessionKey: req.SessionKey,
						MessageID:  messageID,
						Payload:    err.Error(),
					}
					return
				}
				for event := range providerChan {
					out <- event
				}
			}()
			events = out
		}
	}

	if events == nil {
		events, err = cp.streamFromProvider(ctx, finalPrompt, req.SessionKey, messageID, metadata)
		if err != nil {
			return nil, err
		}
	}

	// 6. Ground only turns that actually went through retrieval. A request-level opt-out
	// (ragEnabled=false) keeps the historical behavior.
	if cp.guardrail == nil || !ragEnabled {
		return events, nil
	}

	var repair guardrail.RepairFunc
	if len(usedSources) > 0 && cp.agentRuntime == nil {
		// The agent path is excluded from repair: replaying it would re-run tools.
		repair = func(repairCtx context.Context) (<-chan aisvc.AiChatStreamEvent, error) {
			repairPrompt, err := cp.promptAssembler.AssembleCitationRepair(
				req.Message,
				conversationWindow,
				usedSources,
				agentConstraints,
			)
			if err != nil {
				return nil, err
			}
			return cp.streamFromProvider(repairCtx, repairPrompt, req.SessionKey, messageID, metadata)
		}
	}

	return cp.guardrail.Wrap(ctx, events, req.Message, usedSources, messageID, repair), nil
}

func (cp *ChatPipeline) agentContext(sessionKey string, metadata map[string]any) agent.Context {
	roles := extractRoles(metadata)
	role := agent.RoleDriver
	elevated := false
	for _, item := range roles {
		switch item {
		case "SUPER_ADMIN":
			role = agent.RoleSuperAdmin
			elevated = true
		case "ADMIN":
			if role != agent.RoleSuperAdmin {
				role = agent.RoleAdmin
			}
			elevated = true
		}
	}
	username, _ := metadata["username"].(string)
	userID, _ := metadata["userId"].(string)
	if userID == "" {
		userID = username
	}
	var driverID *int
	switch typed := metadata["driverId"].(type) {
	case int:
		driverID = &typed
	case int64:
		v := int(typed)
		driverID = &v
	case float64:
		v := int(typed)
		driverID = &v
	}
	if driverID == nil && cp.agentRuntime != nil {
		if resolver, ok := cp.agentRuntime.Facade.(interface{ ResolveDriverID(string) *int }); ok {
			driverID = resolver.ResolveDriverID(username)
		}
	}
	return agent.Context{
		Role:       role,
		SessionKey: sessionKey,
		Username:   username,
		UserID:     userID,
		DriverID:   driverID,
		Elevated:   elevated,
	}
}

// isRagEnabled checks if RAG retrieval is enabled for this request
func (cp *ChatPipeline) isRagEnabled(metadata map[string]any) bool {
	if ragEnabled, ok := metadata["ragEnabled"].(bool); ok {
		return ragEnabled
	}
	// Default to true if not specified
	return true
}

// buildRagRequest 构造检索请求与检索身份。
//
// 身份只取自服务端写入的 metadata（username / roles），department 由角色推导，
// 请求体里的同名字段不参与判定。
func (cp *ChatPipeline) buildRagRequest(message string, metadata map[string]any) (ragsvc.RagQueryRequest, ragsvc.RagAccessContext) {
	defaultTopK := 10
	req := ragsvc.RagQueryRequest{
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

	username, _ := metadata["username"].(string)
	return req, ragsvc.NewRagAccessContext(username, serverRoles(metadata))
}

// serverRoles 读取服务端写入的角色集合；没有角色时返回空集合，不套用默认角色。
func serverRoles(metadata map[string]any) []string {
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
	return nil
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
	messageID string,
	metadata map[string]any,
) (<-chan aisvc.AiChatStreamEvent, error) {
	// Get token stream from provider
	tokenChan, errChan := cp.aiProvider.Stream(ctx, prompt, metadata, cp.config)

	// Create output channel
	outChan := make(chan aisvc.AiChatStreamEvent, 10)

	// Launch goroutine to convert tokens to events
	go func() {
		defer close(outChan)

		for {
			select {
			case <-ctx.Done():
				outChan <- aisvc.AiChatStreamEvent{
					Type:       aisvc.ChatStreamEventTypeError,
					SessionKey: sessionKey,
					MessageID:  messageID,
					Payload:    "Request cancelled",
				}
				return
			case err, ok := <-errChan:
				if !ok {
					// Error channel closed, check if we should continue reading tokens
					continue
				}
				if err != nil {
					outChan <- aisvc.AiChatStreamEvent{
						Type:       aisvc.ChatStreamEventTypeError,
						SessionKey: sessionKey,
						MessageID:  messageID,
						Payload:    err.Error(),
					}
					return
				}
			case token, ok := <-tokenChan:
				if !ok {
					// Stream finished normally
					outChan <- aisvc.AiChatStreamEvent{
						Type:       aisvc.ChatStreamEventTypeDone,
						SessionKey: sessionKey,
						MessageID:  messageID,
					}
					return
				}

				// Send token event; the terminal sentinel carries no text of its own.
				if token.Text != "" {
					tokenText := token.Text
					outChan <- aisvc.AiChatStreamEvent{
						Type:       aisvc.ChatStreamEventTypeToken,
						SessionKey: sessionKey,
						MessageID:  messageID,
						Token:      &tokenText,
						Payload:    token,
					}
				}

				// Check if this is the last token
				if token.Finished {
					outChan <- aisvc.AiChatStreamEvent{
						Type:       aisvc.ChatStreamEventTypeDone,
						SessionKey: sessionKey,
						MessageID:  messageID,
					}
					return
				}
			}
		}
	}()

	return outChan, nil
}

// normalizeAiChatConfig ensures all config fields have valid values
func normalizeAiChatConfig(config aisvc.AiChatConfig) aisvc.AiChatConfig {
	defaults := aisvc.DefaultAiChatConfig()

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
