package contract

type SpringAPIGroup struct {
	Domain         string   `json:"domain"`
	Controller     string   `json:"controller"`
	BasePath       string   `json:"basePath"`
	SourcePackage  string   `json:"sourcePackage"`
	GoLegacyPath   string   `json:"goLegacyPath,omitempty"`
	MigrationState string   `json:"migrationState"`
	Notes          []string `json:"notes,omitempty"`
}

type Snapshot struct {
	SourceApplication string           `json:"sourceApplication"`
	TargetFramework   string           `json:"targetFramework"`
	Strategy          string           `json:"strategy"`
	Groups            []SpringAPIGroup `json:"groups"`
	Routes            []RouteSpec      `json:"routes"`
}

func CurrentSnapshot() Snapshot {
	return Snapshot{
		SourceApplication: "finalAssignmentBackend Spring Boot monolith",
		TargetFramework:   "go-zero REST",
		Strategy:          "introduce a parallel go-zero entrypoint and migrate Spring Boot API groups incrementally",
		Groups:            SpringGroups(),
		Routes:            RegisteredRouteSpecs(),
	}
}

func SpringGroups() []SpringAPIGroup {
	return []SpringAPIGroup{
		{
			Domain:         "authentication",
			Controller:     "AuthController",
			BasePath:       "/api/auth",
			SourcePackage:  "controller.auth",
			GoLegacyPath:   "/api/auth",
			MigrationState: "contract-cataloged",
			Notes: []string{
				"Spring Boot exposes login, register, refresh, logout, me and users endpoints.",
				"Go code currently has AuthHandler but depends on an interface contract only.",
			},
		},
		{
			Domain:         "user-management",
			Controller:     "UserManagementController",
			BasePath:       "/api/users",
			SourcePackage:  "controller.admin",
			GoLegacyPath:   "/users",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "roles",
			Controller:     "RoleManagementController",
			BasePath:       "/api/roles",
			SourcePackage:  "controller.admin",
			GoLegacyPath:   "/api/roles",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "permissions",
			Controller:     "PermissionManagementController",
			BasePath:       "/api/permissions",
			SourcePackage:  "controller.admin",
			GoLegacyPath:   "/api/permissions",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "system-settings",
			Controller:     "SystemSettingsController",
			BasePath:       "/api/system/settings",
			SourcePackage:  "controller.admin",
			GoLegacyPath:   "/api/systemSettings",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "backup-restore",
			Controller:     "BackupRestoreController",
			BasePath:       "/api/system/backup",
			SourcePackage:  "controller.admin",
			GoLegacyPath:   "/api/backups",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "vehicles",
			Controller:     "VehicleInformationController",
			BasePath:       "/api/vehicles",
			SourcePackage:  "controller.business",
			GoLegacyPath:   "/api/vehicles",
			MigrationState: "contract-cataloged",
			Notes: []string{
				"Spring Boot now includes driver binding routes and user-aware access control.",
			},
		},
		{
			Domain:         "drivers",
			Controller:     "DriverInformationController",
			BasePath:       "/api/drivers",
			SourcePackage:  "controller.business",
			GoLegacyPath:   "/api/drivers",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "offenses",
			Controller:     "OffenseInformationController",
			BasePath:       "/api/offenses",
			SourcePackage:  "controller.business",
			GoLegacyPath:   "/api/offenses",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "offense-types",
			Controller:     "OffenseTypeController",
			BasePath:       "/api/offense-types",
			SourcePackage:  "controller.business",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "fines",
			Controller:     "FineInformationController",
			BasePath:       "/api/fines",
			SourcePackage:  "controller.business",
			GoLegacyPath:   "/api/fines",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "deductions",
			Controller:     "DeductionInformationController",
			BasePath:       "/api/deductions",
			SourcePackage:  "controller.business",
			GoLegacyPath:   "/api/deductions",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "appeals",
			Controller:     "AppealManagementController",
			BasePath:       "/api/appeals",
			SourcePackage:  "controller.business",
			GoLegacyPath:   "/api/appeals",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "payments",
			Controller:     "PaymentRecordController",
			BasePath:       "/api/payments",
			SourcePackage:  "controller.business",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "progress",
			Controller:     "ProgressItemController",
			BasePath:       "/api/progress",
			SourcePackage:  "controller.business",
			GoLegacyPath:   "/api/progress",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "violations-dashboard",
			Controller:     "TrafficViolationController",
			BasePath:       "/api/violations",
			SourcePackage:  "controller.business",
			GoLegacyPath:   "/api/traffic-violations",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "workflow",
			Controller:     "WorkflowController",
			BasePath:       "/api/workflow",
			SourcePackage:  "controller.business",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "login-logs",
			Controller:     "LoginLogController",
			BasePath:       "/api/logs/login",
			SourcePackage:  "controller.audit",
			GoLegacyPath:   "/api/loginLogs",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "operation-logs",
			Controller:     "OperationLogController",
			BasePath:       "/api/logs/operation",
			SourcePackage:  "controller.audit",
			GoLegacyPath:   "/api/operationLogs",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "system-logs",
			Controller:     "SystemLogsController",
			BasePath:       "/api/system/logs",
			SourcePackage:  "controller.audit",
			GoLegacyPath:   "/api/systemLogs",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "offense-details-view",
			Controller:     "OffenseDetailsController",
			BasePath:       "/api/view/offenses",
			SourcePackage:  "controller.view",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "ai-chat",
			Controller:     "AiChatController",
			BasePath:       "/api/ai/chat",
			SourcePackage:  "ai.chat",
			MigrationState: "contract-cataloged",
			Notes: []string{
				"Spring Boot exposes an SSE streaming endpoint and legacy JSON endpoints.",
			},
		},
		{
			Domain:         "rag-query",
			Controller:     "RagQueryController",
			BasePath:       "/api/rag",
			SourcePackage:  "ai.rag.query",
			MigrationState: "contract-cataloged",
		},
		{
			Domain:         "rag-admin",
			Controller:     "RagManagementController",
			BasePath:       "/api/rag/admin",
			SourcePackage:  "controller.rag",
			MigrationState: "contract-cataloged",
		},
	}
}
