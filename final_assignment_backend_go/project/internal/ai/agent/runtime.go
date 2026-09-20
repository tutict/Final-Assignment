package agent

import (
	"time"
)

type Runtime struct {
	Registry *Registry
	Store    *DraftStore
	Facade   Facade
}

func NewRuntime(facade Facade) *Runtime {
	store := NewDraftStore()
	registry := NewRegistry()
	confirm := ConfirmDraftTool{Store: store, Registry: registry}
	tools := []Tool{
		QueryOffensesTool{Facade: facade},
		QueryOffensesAdminTool{Facade: facade},
		QueryFinesTool{Facade: facade},
		QueryFinesAdminTool{Facade: facade},
		QueryAppealsTool{Facade: facade},
		QueryAppealsAdminTool{Facade: facade},
		NavigateBackupTool{},
		PrepareAppealTool{Facade: facade},
		PrepareOffenseCreateTool{Facade: facade},
		confirm,
	}
	registry = NewRegistry(tools...)
	confirm.Registry = registry
	registry.tools[confirm.Name()] = confirm
	return &Runtime{Registry: registry, Store: store, Facade: facade}
}

func (rt *Runtime) Execute(message string, ctx Context) []Event {
	now := time.Now()
	var calls []Call
	if IsConfirm(message) {
		args := map[string]any{}
		if draftID := ExtractDraftID(message); draftID != "" {
			args["draftId"] = draftID
		}
		calls = append(calls, Call{ID: "confirm", Name: "confirm_draft", Arguments: args})
	} else {
		calls = Route(message, string(ctx.Role))
	}
	events := make([]Event, 0)
	for _, call := range calls {
		events = append(events, Event{Type: "tool", SessionKey: ctx.SessionKey, Payload: map[string]any{"phase": "start", "name": call.Name, "id": call.ID}, Timestamp: now})
		result := rt.invoke(call, ctx)
		events = append(events, rt.toEvents(result, ctx, call.Name)...)
		events = append(events, Event{Type: "tool", SessionKey: ctx.SessionKey, Payload: map[string]any{"phase": "end", "name": call.Name, "id": call.ID, "ok": result.OK}, Timestamp: now})
	}
	return events
}

func (rt *Runtime) invoke(call Call, ctx Context) Result {
	tool, ok := rt.Registry.Find(call.Name)
	if !ok {
		return Result{Kind: KindError, Summary: "未知工具: " + call.Name}
	}
	if !allowed(tool, ctx.Role) {
		return Result{Kind: KindError, Summary: "当前角色无权使用工具 " + call.Name}
	}
	result := tool.Execute(ctx, call.Arguments)
	if result.Draft != nil {
		rt.Store.Save(*result.Draft)
	}
	return result
}

func (rt *Runtime) toEvents(result Result, ctx Context, toolName string) []Event {
	now := time.Now()
	if result.Kind == KindDraft && result.Draft != nil {
		payload := map[string]any{
			"draftId":     result.Draft.DraftID,
			"summary":     result.Draft.Summary,
			"risk":        result.Draft.Risk,
			"serviceName": result.Draft.ServiceName,
			"preview":     result.Draft.Preview,
			"expiresAt":   result.Draft.ExpiresAt.Format(time.RFC3339),
		}
		return []Event{{Type: "draft", SessionKey: ctx.SessionKey, Payload: payload, Timestamp: now}}
	}
	if result.Kind == KindAction && result.Navigate != nil {
		return []Event{actionEvent(ctx, result.Navigate, result.Summary, now)}
	}
	payload := map[string]any{"name": toolName, "summary": result.Summary, "ok": result.OK, "items": result.Items}
	events := []Event{{Type: "result", SessionKey: ctx.SessionKey, Payload: payload, Timestamp: now}}
	if result.Navigate != nil {
		events = append(events, actionEvent(ctx, result.Navigate, result.Summary, now))
	}
	return events
}

func actionEvent(ctx Context, action *Action, summary string, now time.Time) Event {
	return Event{Type: "action", SessionKey: ctx.SessionKey, Payload: map[string]any{
		"type": action.Type, "label": action.Label, "target": action.Target, "value": action.Value, "summary": summary,
	}, Timestamp: now}
}
