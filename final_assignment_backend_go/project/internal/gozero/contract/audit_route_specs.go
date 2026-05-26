package contract

import "net/http"

func AuditRouteSpecs() []RouteSpec {
	routes := []RouteSpec{}
	routes = append(routes, LoginLogRouteSpecs()...)
	routes = append(routes, OperationLogRouteSpecs()...)
	routes = append(routes, SystemLogRouteSpecs()...)
	return routes
}

func LoginLogRouteSpecs() []RouteSpec {
	return []RouteSpec{
		loginLogRoute(http.MethodPost, "/api/logs/login", "createLoginLog", "@PostMapping"),
		loginLogRoute(http.MethodGet, "/api/logs/login", "listLoginLogs", "@GetMapping"),
		loginLogRoute(http.MethodGet, "/api/logs/login/search/username", "searchByUsername", `@GetMapping("/search/username")`),
		loginLogRoute(http.MethodGet, "/api/logs/login/search/result", "searchByResult", `@GetMapping("/search/result")`),
		loginLogRoute(http.MethodGet, "/api/logs/login/search/time-range", "searchByTimeRange", `@GetMapping("/search/time-range")`),
		loginLogRoute(http.MethodGet, "/api/logs/login/search/ip", "searchByIp", `@GetMapping("/search/ip")`),
		loginLogRoute(http.MethodGet, "/api/logs/login/search/location", "searchByLocation", `@GetMapping("/search/location")`),
		loginLogRoute(http.MethodGet, "/api/logs/login/search/device-type", "searchByDeviceType", `@GetMapping("/search/device-type")`),
		loginLogRoute(http.MethodGet, "/api/logs/login/search/browser-type", "searchByBrowserType", `@GetMapping("/search/browser-type")`),
		loginLogRoute(http.MethodGet, "/api/logs/login/search/logout-time-range", "searchByLogoutTimeRange", `@GetMapping("/search/logout-time-range")`),
		loginLogRoute(http.MethodPut, "/api/logs/login/:logId", "updateLoginLog", `@PutMapping("/{logId}")`),
		loginLogRoute(http.MethodDelete, "/api/logs/login/:logId", "deleteLoginLog", `@DeleteMapping("/{logId}")`),
		loginLogRoute(http.MethodGet, "/api/logs/login/:logId", "getLoginLog", `@GetMapping("/{logId}")`),
	}
}

func OperationLogRouteSpecs() []RouteSpec {
	return []RouteSpec{
		operationLogRoute(http.MethodPost, "/api/logs/operation", "createOperationLog", "@PostMapping"),
		operationLogRoute(http.MethodGet, "/api/logs/operation", "listOperationLogs", "@GetMapping"),
		operationLogRoute(http.MethodGet, "/api/logs/operation/search/module", "searchByModule", `@GetMapping("/search/module")`),
		operationLogRoute(http.MethodGet, "/api/logs/operation/search/type", "searchByType", `@GetMapping("/search/type")`),
		operationLogRoute(http.MethodGet, "/api/logs/operation/search/user/:userId", "searchByUser", `@GetMapping("/search/user/{userId}")`),
		operationLogRoute(http.MethodGet, "/api/logs/operation/search/time-range", "searchByTimeRange", `@GetMapping("/search/time-range")`),
		operationLogRoute(http.MethodGet, "/api/logs/operation/search/username", "searchByUsername", `@GetMapping("/search/username")`),
		operationLogRoute(http.MethodGet, "/api/logs/operation/search/request-url", "searchByRequestUrl", `@GetMapping("/search/request-url")`),
		operationLogRoute(http.MethodGet, "/api/logs/operation/search/request-method", "searchByRequestMethod", `@GetMapping("/search/request-method")`),
		operationLogRoute(http.MethodGet, "/api/logs/operation/search/result", "searchByResult", `@GetMapping("/search/result")`),
		operationLogRoute(http.MethodPut, "/api/logs/operation/:logId", "updateOperationLog", `@PutMapping("/{logId}")`),
		operationLogRoute(http.MethodDelete, "/api/logs/operation/:logId", "deleteOperationLog", `@DeleteMapping("/{logId}")`),
		operationLogRoute(http.MethodGet, "/api/logs/operation/:logId", "getOperationLog", `@GetMapping("/{logId}")`),
	}
}

func SystemLogRouteSpecs() []RouteSpec {
	return []RouteSpec{
		systemLogRoute(http.MethodGet, "/api/system/logs/overview", "overview", `@GetMapping("/overview")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/login/recent", "recentLoginLogs", `@GetMapping("/login/recent")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/operation/recent", "recentOperationLogs", `@GetMapping("/operation/recent")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/idempotency", "searchRequestsByIdempotency", `@GetMapping("/requests/search/idempotency")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/method", "searchRequestsByMethod", `@GetMapping("/requests/search/method")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/url", "searchRequestsByURL", `@GetMapping("/requests/search/url")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/business-type", "searchRequestsByBusinessType", `@GetMapping("/requests/search/business-type")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/business-id", "searchRequestsByBusinessID", `@GetMapping("/requests/search/business-id")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/status", "searchRequestsByStatus", `@GetMapping("/requests/search/status")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/user", "searchRequestsByUser", `@GetMapping("/requests/search/user")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/ip", "searchRequestsByIP", `@GetMapping("/requests/search/ip")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/search/time-range", "searchRequestsByTimeRange", `@GetMapping("/requests/search/time-range")`),
		systemLogRoute(http.MethodGet, "/api/system/logs/requests/:historyId", "getRequestHistory", `@GetMapping("/requests/{historyId}")`),
	}
}

func loginLogRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "login-logs", operation, "LoginLogController", mapping)
}

func operationLogRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "operation-logs", operation, "OperationLogController", mapping)
}

func systemLogRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "system-logs", operation, "SystemLogsController", mapping)
}
