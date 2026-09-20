package agent

import (
	"testing"
	"time"
)

type fakeFacade struct {
	offenses []map[string]any
	created  bool
}

func (f *fakeFacade) ListOffenses(ctx Context, driverID *int) ([]map[string]any, error) {
	if driverID != nil && ctx.DriverID != nil && *driverID != *ctx.DriverID && !ctx.Elevated {
		return []map[string]any{}, nil
	}
	return f.offenses, nil
}
func (f *fakeFacade) CreateOffense(Context, map[string]any) (map[string]any, error) {
	return map[string]any{"offenseId": 1}, nil
}
func (f *fakeFacade) ListFines(Context, *int) ([]map[string]any, error) { return nil, nil }
func (f *fakeFacade) CreateFine(Context, map[string]any) (map[string]any, error) {
	return map[string]any{}, nil
}
func (f *fakeFacade) ListAppeals(Context, *int) ([]map[string]any, error) { return nil, nil }
func (f *fakeFacade) CreateAppeal(Context, map[string]any) (map[string]any, error) {
	f.created = true
	return map[string]any{"appealId": 88}, nil
}

func TestDriverQueryUsesOwnDriverID(t *testing.T) {
	driverID := 100
	facade := &fakeFacade{offenses: []map[string]any{{"offenseId": 11.0, "driverId": 100.0}}}
	tool := QueryOffensesTool{Facade: facade}
	result := tool.Execute(Context{Role: RoleDriver, Username: "u", UserID: "10", DriverID: &driverID}, map[string]any{"driverId": 999})
	if !result.OK || len(result.Items) != 1 {
		t.Fatalf("result=%+v", result)
	}
}

func TestConfirmDraftRejectsForeignUser(t *testing.T) {
	facade := &fakeFacade{}
	rt := NewRuntime(facade)
	now := time.Now()
	rt.Store.Save(Draft{DraftID: "d1", UserID: "other", SessionKey: "s1", ToolName: "prepare_appeal", Payload: map[string]any{"offenseId": 8}, CreatedAt: now, ExpiresAt: now.Add(time.Minute)})
	result := ConfirmDraftTool{Store: rt.Store, Registry: rt.Registry}.Execute(Context{Role: RoleDriver, Username: "u", UserID: "10", SessionKey: "s1"}, map[string]any{"draftId": "d1"})
	if result.OK || result.Summary == "" {
		t.Fatalf("expected rejection, got %+v", result)
	}
	if facade.created {
		t.Fatal("foreign draft must not write")
	}
}

func TestPrepareAppealRequiresConfirm(t *testing.T) {
	facade := &fakeFacade{}
	tool := PrepareAppealTool{Facade: facade}
	result := tool.Execute(Context{Role: RoleDriver, Username: "u", UserID: "10"}, map[string]any{"offenseId": 8})
	if result.Kind != KindDraft || facade.created {
		t.Fatalf("expected draft, got %+v created=%v", result, facade.created)
	}
}
