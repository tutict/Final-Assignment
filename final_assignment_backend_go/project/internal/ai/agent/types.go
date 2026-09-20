package agent

import "time"

type Role string

const (
	RoleDriver     Role = "DRIVER"
	RoleAdmin      Role = "ADMIN"
	RoleSuperAdmin Role = "SUPER_ADMIN"
)

type Context struct {
	Role       Role
	SessionKey string
	Username   string
	UserID     string
	DriverID   *int
	Confirmed  bool
	DraftID    string
	Elevated   bool
}

func (c Context) UserKey() string {
	if c.UserID != "" {
		return c.UserID
	}
	if c.Username != "" {
		return c.Username
	}
	return "anonymous"
}

type Call struct {
	ID        string
	Name      string
	Arguments map[string]any
}

type Action struct {
	Type   string `json:"type"`
	Label  string `json:"label"`
	Target string `json:"target"`
	Value  string `json:"value"`
}

type Result struct {
	OK       bool
	Kind     string
	Summary  string
	Items    []map[string]any
	Navigate *Action
	Draft    *Draft
}

const (
	KindResult = "result"
	KindDraft  = "draft"
	KindError  = "error"
	KindAction = "action"
)

type Tool interface {
	Name() string
	Roles() []Role
	Mutation() bool
	Execute(ctx Context, args map[string]any) Result
}

type Event struct {
	Type       string    `json:"type"`
	SessionKey string    `json:"sessionKey"`
	MessageID  string    `json:"messageId"`
	Token      *string   `json:"token"`
	Payload    any       `json:"payload"`
	Timestamp  time.Time `json:"timestamp"`
}

type Facade interface {
	ListOffenses(ctx Context, driverID *int) ([]map[string]any, error)
	CreateOffense(ctx Context, args map[string]any) (map[string]any, error)
	ListFines(ctx Context, driverID *int) ([]map[string]any, error)
	CreateFine(ctx Context, args map[string]any) (map[string]any, error)
	ListAppeals(ctx Context, driverID *int) ([]map[string]any, error)
	CreateAppeal(ctx Context, args map[string]any) (map[string]any, error)
}
