package agent

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

type Registry struct {
	tools map[string]Tool
}

func NewRegistry(tools ...Tool) *Registry {
	reg := &Registry{tools: map[string]Tool{}}
	for _, tool := range tools {
		reg.tools[tool.Name()] = tool
	}
	return reg
}

func (r *Registry) Find(name string) (Tool, bool) {
	tool, ok := r.tools[name]
	return tool, ok
}

func allowed(tool Tool, role Role) bool {
	for _, candidate := range tool.Roles() {
		if candidate == role {
			return true
		}
	}
	return false
}

func queryResult(empty, found string, items []map[string]any, label, target string) Result {
	summary := empty
	if len(items) > 0 {
		summary = fmt.Sprintf(found, len(items))
	}
	return Result{OK: true, Kind: KindResult, Summary: summary, Items: items, Navigate: &Action{Type: "NAVIGATE", Label: label, Target: target, Value: `{"source":"agent_tool"}`}}
}

type QueryOffensesTool struct{ Facade Facade }

func (t QueryOffensesTool) Name() string   { return "query_my_offenses" }
func (t QueryOffensesTool) Roles() []Role  { return []Role{RoleDriver} }
func (t QueryOffensesTool) Mutation() bool { return false }
func (t QueryOffensesTool) Execute(ctx Context, _ map[string]any) Result {
	if ctx.DriverID == nil {
		return Result{Kind: KindError, Summary: "当前账号尚未绑定驾驶员档案，无法查询违法记录。"}
	}
	items, err := t.Facade.ListOffenses(ctx, ctx.DriverID)
	if err != nil {
		return Result{Kind: KindError, Summary: err.Error()}
	}
	return queryResult("没有查询到您的违法记录。", "共找到 %d 条违法记录。", items, "查看违法详情", "/userOffenseListPage")
}

type QueryOffensesAdminTool struct{ Facade Facade }

func (t QueryOffensesAdminTool) Name() string   { return "query_offenses" }
func (t QueryOffensesAdminTool) Roles() []Role  { return []Role{RoleAdmin, RoleSuperAdmin} }
func (t QueryOffensesAdminTool) Mutation() bool { return false }
func (t QueryOffensesAdminTool) Execute(ctx Context, args map[string]any) Result {
	items, err := t.Facade.ListOffenses(ctx, intArg(args, "driverId", "id"))
	if err != nil {
		return Result{Kind: KindError, Summary: err.Error()}
	}
	return queryResult("没有查询到违法记录。", "共找到 %d 条违法记录。", items, "打开违法管理", "/offenseList")
}

type QueryFinesTool struct{ Facade Facade }

func (t QueryFinesTool) Name() string   { return "query_my_fines" }
func (t QueryFinesTool) Roles() []Role  { return []Role{RoleDriver} }
func (t QueryFinesTool) Mutation() bool { return false }
func (t QueryFinesTool) Execute(ctx Context, _ map[string]any) Result {
	if ctx.DriverID == nil {
		return Result{Kind: KindError, Summary: "当前账号尚未绑定驾驶员档案，无法查询罚款。"}
	}
	items, err := t.Facade.ListFines(ctx, ctx.DriverID)
	if err != nil {
		return Result{Kind: KindError, Summary: err.Error()}
	}
	return queryResult("没有查询到您的罚款记录。", "共找到 %d 条罚款记录。", items, "查看罚款信息", "/fineInformation")
}

type QueryFinesAdminTool struct{ Facade Facade }

func (t QueryFinesAdminTool) Name() string   { return "query_fines" }
func (t QueryFinesAdminTool) Roles() []Role  { return []Role{RoleAdmin, RoleSuperAdmin} }
func (t QueryFinesAdminTool) Mutation() bool { return false }
func (t QueryFinesAdminTool) Execute(ctx Context, args map[string]any) Result {
	items, err := t.Facade.ListFines(ctx, intArg(args, "driverId", "id"))
	if err != nil {
		return Result{Kind: KindError, Summary: err.Error()}
	}
	return queryResult("没有查询到罚款记录。", "共找到 %d 条罚款记录。", items, "打开罚款管理", "/fineInformation")
}

type QueryAppealsTool struct{ Facade Facade }

func (t QueryAppealsTool) Name() string   { return "query_my_appeals" }
func (t QueryAppealsTool) Roles() []Role  { return []Role{RoleDriver} }
func (t QueryAppealsTool) Mutation() bool { return false }
func (t QueryAppealsTool) Execute(ctx Context, _ map[string]any) Result {
	if ctx.DriverID == nil {
		return Result{Kind: KindError, Summary: "当前账号尚未绑定驾驶员档案，无法查询申诉。"}
	}
	items, err := t.Facade.ListAppeals(ctx, ctx.DriverID)
	if err != nil {
		return Result{Kind: KindError, Summary: err.Error()}
	}
	return queryResult("没有查询到您的申诉记录。", "共找到 %d 条申诉记录。", items, "查看我的申诉", "/userAppeal")
}

type QueryAppealsAdminTool struct{ Facade Facade }

func (t QueryAppealsAdminTool) Name() string   { return "query_appeals" }
func (t QueryAppealsAdminTool) Roles() []Role  { return []Role{RoleAdmin, RoleSuperAdmin} }
func (t QueryAppealsAdminTool) Mutation() bool { return false }
func (t QueryAppealsAdminTool) Execute(ctx Context, args map[string]any) Result {
	items, err := t.Facade.ListAppeals(ctx, intArg(args, "driverId", "id"))
	if err != nil {
		return Result{Kind: KindError, Summary: err.Error()}
	}
	return queryResult("没有查询到申诉记录。", "共找到 %d 条申诉记录。", items, "打开申诉管理", "/appealManagement")
}

type NavigateBackupTool struct{}

func (NavigateBackupTool) Name() string   { return "navigate_backup" }
func (NavigateBackupTool) Roles() []Role  { return []Role{RoleSuperAdmin} }
func (NavigateBackupTool) Mutation() bool { return false }
func (NavigateBackupTool) Execute(Context, map[string]any) Result {
	return Result{OK: true, Kind: KindAction, Summary: "备份恢复需要在系统页面人工确认，助手不会自动执行。", Navigate: &Action{Type: "NAVIGATE", Label: "打开备份与恢复", Target: "/admin/backupAndRestore", Value: `{"source":"agent_tool"}`}}
}

type PrepareAppealTool struct{ Facade Facade }

func (t PrepareAppealTool) Name() string   { return "prepare_appeal" }
func (t PrepareAppealTool) Roles() []Role  { return []Role{RoleDriver, RoleAdmin, RoleSuperAdmin} }
func (t PrepareAppealTool) Mutation() bool { return true }
func (t PrepareAppealTool) Execute(ctx Context, args map[string]any) Result {
	if !ctx.Confirmed {
		now := time.Now()
		draft := Draft{
			DraftID: uuid.NewString(), UserID: ctx.UserKey(), SessionKey: ctx.SessionKey,
			ToolName: t.Name(), ServiceName: "AppealManagementService.createAppeal", Risk: "high",
			Summary: "即将提交申诉，请确认后办理。", Preview: args, Payload: args, CreatedAt: now, ExpiresAt: now.Add(10 * time.Minute),
		}
		return Result{OK: true, Kind: KindDraft, Summary: draft.Summary, Draft: &draft}
	}
	saved, err := t.Facade.CreateAppeal(ctx, args)
	if err != nil {
		return Result{Kind: KindError, Summary: err.Error()}
	}
	return Result{OK: true, Kind: KindResult, Summary: fmt.Sprintf("申诉已提交，ID %v。", saved["appealId"]), Items: []map[string]any{saved}, Navigate: &Action{Type: "NAVIGATE", Label: "查看我的申诉", Target: "/userAppeal", Value: `{"source":"agent_tool"}`}}
}

type PrepareOffenseCreateTool struct{ Facade Facade }

func (t PrepareOffenseCreateTool) Name() string   { return "prepare_offense_create" }
func (t PrepareOffenseCreateTool) Roles() []Role  { return []Role{RoleAdmin, RoleSuperAdmin} }
func (t PrepareOffenseCreateTool) Mutation() bool { return true }
func (t PrepareOffenseCreateTool) Execute(ctx Context, args map[string]any) Result {
	if !ctx.Confirmed {
		now := time.Now()
		draft := Draft{DraftID: uuid.NewString(), UserID: ctx.UserKey(), SessionKey: ctx.SessionKey, ToolName: t.Name(), ServiceName: "OffenseInformationService.CreateOffense", Risk: "high", Summary: "即将录入违法记录，请确认后办理。", Preview: args, Payload: args, CreatedAt: now, ExpiresAt: now.Add(10 * time.Minute)}
		return Result{OK: true, Kind: KindDraft, Summary: draft.Summary, Draft: &draft}
	}
	saved, err := t.Facade.CreateOffense(ctx, args)
	if err != nil {
		return Result{Kind: KindError, Summary: err.Error()}
	}
	return Result{OK: true, Kind: KindResult, Summary: fmt.Sprintf("违法记录已录入，ID %v。", saved["offenseId"]), Items: []map[string]any{saved}, Navigate: &Action{Type: "NAVIGATE", Label: "打开违法管理", Target: "/offenseList", Value: `{"source":"agent_tool"}`}}
}

type ConfirmDraftTool struct {
	Store    *DraftStore
	Registry *Registry
}

func (t ConfirmDraftTool) Name() string   { return "confirm_draft" }
func (t ConfirmDraftTool) Roles() []Role  { return []Role{RoleDriver, RoleAdmin, RoleSuperAdmin} }
func (t ConfirmDraftTool) Mutation() bool { return true }
func (t ConfirmDraftTool) Execute(ctx Context, args map[string]any) Result {
	draftID, _ := args["draftId"].(string)
	if draftID == "" {
		draftID, _ = t.Store.LastDraftID(ctx.UserKey(), ctx.SessionKey)
	}
	draft, ok := t.Store.Find(draftID)
	if !ok {
		return Result{Kind: KindError, Summary: "没有待确认的办理草稿，或草稿已过期。"}
	}
	if draft.UserID != ctx.UserKey() {
		return Result{Kind: KindError, Summary: "不能确认其他用户的办理草稿。"}
	}
	tool, ok := t.Registry.Find(draft.ToolName)
	if !ok {
		return Result{Kind: KindError, Summary: "草稿对应的工具已失效。"}
	}
	if !allowed(tool, ctx.Role) {
		return Result{Kind: KindError, Summary: "当前角色无权确认该办理草稿。"}
	}
	confirmed := ctx
	confirmed.Confirmed = true
	confirmed.DraftID = draft.DraftID
	result := tool.Execute(confirmed, draft.Payload)
	if result.OK {
		t.Store.Delete(draft.DraftID)
	}
	return result
}

func intArg(args map[string]any, keys ...string) *int {
	if args == nil {
		return nil
	}
	for _, key := range keys {
		value, ok := args[key]
		if !ok || value == nil {
			continue
		}
		switch typed := value.(type) {
		case int:
			return &typed
		case int64:
			v := int(typed)
			return &v
		case float64:
			v := int(typed)
			return &v
		}
	}
	return nil
}
