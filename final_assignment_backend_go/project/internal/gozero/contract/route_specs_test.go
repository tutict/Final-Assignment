package contract

import "testing"

func TestRegisteredRouteSpecsHaveNoDuplicates(t *testing.T) {
	seen := make(map[string]RouteSpec)
	for _, spec := range RegisteredRouteSpecs() {
		key := spec.Method + " " + spec.Path
		if previous, ok := seen[key]; ok {
			t.Fatalf("duplicate route spec %s for %s and %s", key, previous.Operation, spec.Operation)
		}
		seen[key] = spec
	}
}

func TestRegisteredRouteSpecsIncludeAdminAndAuditContracts(t *testing.T) {
	routes := make(map[string]RouteSpec)
	for _, spec := range RegisteredRouteSpecs() {
		routes[spec.Method+" "+spec.Path] = spec
	}

	required := map[string]string{
		"POST /api/users": "UserManagementController",
		"GET /api/roles/permissions/by-permission/:permissionId": "RoleManagementController",
		"GET /api/system/settings/dicts/search/status":           "SystemSettingsController",
		"GET /api/logs/operation/search/user/:userId":            "OperationLogController",
		"GET /api/system/logs/requests/search/idempotency":       "SystemLogsController",
	}

	for key, controller := range required {
		spec, ok := routes[key]
		if !ok {
			t.Fatalf("missing route spec %s", key)
		}
		if spec.Controller != controller {
			t.Fatalf("route spec %s controller = %s, want %s", key, spec.Controller, controller)
		}
	}
}

func TestRegisteredRouteSpecsIncludeBusinessContracts(t *testing.T) {
	routes := make(map[string]RouteSpec)
	for _, spec := range RegisteredRouteSpecs() {
		routes[spec.Method+" "+spec.Path] = spec
	}

	required := map[string]string{
		"GET /api/drivers/search/id-card":                      "DriverInformationController",
		"GET /api/offenses/:offenseId/details":                 "OffenseInformationController",
		"GET /api/offense-types/search/points-range":           "OffenseTypeController",
		"GET /api/fines/search/date-range":                     "FineInformationController",
		"GET /api/deductions/search/time-range":                "DeductionInformationController",
		"POST /api/appeals/:appealId/reviews":                  "AppealManagementController",
		"PUT /api/payments/:paymentId/status/:state":           "PaymentRecordController",
		"GET /api/progress/idempotency/:key":                   "ProgressItemController",
		"POST /api/workflow/payments/:paymentId/events/:event": "WorkflowController",
		"GET /api/view/offenses/:offenseId":                    "OffenseDetailsController",
		"GET /api/violations/status":                           "TrafficViolationController",
	}

	for key, controller := range required {
		spec, ok := routes[key]
		if !ok {
			t.Fatalf("missing route spec %s", key)
		}
		if spec.Controller != controller {
			t.Fatalf("route spec %s controller = %s, want %s", key, spec.Controller, controller)
		}
	}
}

func TestRegisteredRouteSpecsIncludeAIContracts(t *testing.T) {
	routes := make(map[string]RouteSpec)
	for _, spec := range RegisteredRouteSpecs() {
		routes[spec.Method+" "+spec.Path] = spec
	}

	required := map[string]string{
		"POST /api/ai/chat/stream":                    "AiChatController",
		"GET /api/ai/chat/actions":                    "AiChatController",
		"POST /api/rag/query":                         "RagQueryController",
		"POST /api/rag/admin/documents/upload":        "RagManagementController",
		"POST /api/rag/admin/documents/manual":        "RagManagementController",
		"POST /api/rag/admin/backfill/run":            "RagManagementController",
		"POST /api/rag/admin/embedding/requeue":       "RagManagementController",
		"POST /api/rag/admin/index/migrate":           "RagManagementController",
		"DELETE /api/rag/admin/documents/:documentId": "RagManagementController",
	}

	for key, controller := range required {
		spec, ok := routes[key]
		if !ok {
			t.Fatalf("missing route spec %s", key)
		}
		if spec.Controller != controller {
			t.Fatalf("route spec %s controller = %s, want %s", key, spec.Controller, controller)
		}
	}
}

func TestSpringGroupsHaveRegisteredRoutes(t *testing.T) {
	routeCounts := make(map[string]int)
	for _, spec := range RegisteredRouteSpecs() {
		routeCounts[spec.Domain]++
	}

	for _, group := range SpringGroups() {
		if routeCounts[group.Domain] == 0 {
			t.Fatalf("spring group %s (%s) has no registered route specs", group.Domain, group.Controller)
		}
	}
}
