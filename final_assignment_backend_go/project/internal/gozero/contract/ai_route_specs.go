package contract

import "net/http"

func AIRouteSpecs() []RouteSpec {
	routes := []RouteSpec{}
	routes = append(routes, AiChatRouteSpecs()...)
	routes = append(routes, RagQueryRouteSpecs()...)
	routes = append(routes, RagManagementRouteSpecs()...)
	return routes
}

func AiChatRouteSpecs() []RouteSpec {
	return []RouteSpec{
		aiChatRoute(http.MethodPost, "/api/ai/chat/stream", "stream", `@PostMapping(value = "/stream")`),
		aiChatRoute(http.MethodGet, "/api/ai/chat", "chatLegacy", "@GetMapping"),
		aiChatRoute(http.MethodGet, "/api/ai/chat/actions", "getChatActions", `@GetMapping("/actions")`),
	}
}

func RagQueryRouteSpecs() []RouteSpec {
	return []RouteSpec{
		ragQueryRoute(http.MethodPost, "/api/rag/query", "query", `@PostMapping("/query")`),
	}
}

func RagManagementRouteSpecs() []RouteSpec {
	return []RouteSpec{
		ragManagementRoute(http.MethodGet, "/api/rag/admin/overview", "overview", `@GetMapping("/overview")`),
		ragManagementRoute(http.MethodGet, "/api/rag/admin/documents", "listDocuments", `@GetMapping("/documents")`),
		ragManagementRoute(http.MethodPost, "/api/rag/admin/documents/upload", "uploadDocument", `@PostMapping(value = "/documents/upload")`),
		ragManagementRoute(http.MethodPost, "/api/rag/admin/documents/manual", "createManualDocument", `@PostMapping("/documents/manual")`),
		ragManagementRoute(http.MethodPost, "/api/rag/admin/backfill", "runBackfill", `@PostMapping("/backfill")`),
		ragManagementRoute(http.MethodPost, "/api/rag/admin/backfill/run", "runBackfillBatches", `@PostMapping("/backfill/run")`),
		ragManagementRoute(http.MethodPost, "/api/rag/admin/embedding/run", "runEmbeddingBatch", `@PostMapping("/embedding/run")`),
		ragManagementRoute(http.MethodPost, "/api/rag/admin/embedding/requeue", "requeueEmbeddingTasks", `@PostMapping("/embedding/requeue")`),
		ragManagementRoute(http.MethodPost, "/api/rag/admin/index/migrate", "migrateIndex", `@PostMapping("/index/migrate")`),
		ragManagementRoute(http.MethodDelete, "/api/rag/admin/documents/:documentId", "deleteDocument", `@DeleteMapping("/documents/{documentId}")`),
	}
}

func aiChatRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "ai-chat", operation, "AiChatController", mapping)
}

func ragQueryRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "rag-query", operation, "RagQueryController", mapping)
}

func ragManagementRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "rag-admin", operation, "RagManagementController", mapping)
}
