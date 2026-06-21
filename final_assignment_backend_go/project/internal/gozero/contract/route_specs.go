package contract

import "net/http"

type RouteSpec struct {
	Method         string `json:"method"`
	Path           string `json:"path"`
	Domain         string `json:"domain"`
	Operation      string `json:"operation"`
	Controller     string `json:"controller"`
	SpringMapping  string `json:"springMapping"`
	MigrationState string `json:"migrationState"`
}

func RegisteredRouteSpecs() []RouteSpec {
	routes := []RouteSpec{}
	routes = append(routes, SystemRouteSpecs()...)
	routes = append(routes, AuthRouteSpecs()...)
	routes = append(routes, AdminRouteSpecs()...)
	routes = append(routes, VehicleRouteSpecs()...)
	routes = append(routes, BusinessRouteSpecs()...)
	routes = append(routes, AuditRouteSpecs()...)
	routes = append(routes, AIRouteSpecs()...)
	return routes
}

func SystemRouteSpecs() []RouteSpec {
	return []RouteSpec{
		systemRoute(http.MethodGet, "/actuator/health", "health", "implemented"),
		systemRoute(http.MethodGet, "/api/health", "health", "implemented"),
		systemRoute(http.MethodGet, "/api/contracts", "contracts", "implemented"),
		systemRoute(http.MethodGet, "/api/go-zero/contracts", "contracts", "implemented"),
		systemRoute(http.MethodGet, "/api/go-zero/routes", "routes", "implemented"),
	}
}

func AuthRouteSpecs() []RouteSpec {
	return []RouteSpec{
		authRoute(http.MethodPost, "/api/auth/login", "login", `@PostMapping("/login")`),
		authRoute(http.MethodPost, "/api/auth/register", "registerUser", `@PostMapping("/register")`),
		authRoute(http.MethodPost, "/api/auth/refresh", "refresh", `@PostMapping("/refresh")`),
		authRoute(http.MethodPost, "/api/auth/logout", "logout", `@PostMapping("/logout")`),
		authRoute(http.MethodGet, "/api/auth/me", "getCurrentUser", `@GetMapping("/me")`),
		authRoute(http.MethodGet, "/api/auth/users", "getAllUsers", `@GetMapping("/users")`),
	}
}

func VehicleRouteSpecs() []RouteSpec {
	return []RouteSpec{
		vehicleRoute(http.MethodPost, "/api/vehicles", "createVehicle", "@PostMapping"),
		vehicleRoute(http.MethodGet, "/api/vehicles", "listVehicles", "@GetMapping"),
		vehicleRoute(http.MethodGet, "/api/vehicles/search/license", "searchByLicense", `@GetMapping("/search/license")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/search/owner", "searchByOwnerIdCard", `@GetMapping("/search/owner")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/search/type", "searchByType", `@GetMapping("/search/type")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/search/owner/name", "searchByOwnerName", `@GetMapping("/search/owner/name")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/search/status", "searchByStatus", `@GetMapping("/search/status")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/search/general", "searchVehicles", `@GetMapping("/search/general")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/search/license/global", "globalPlateSuggestions", `@GetMapping("/search/license/global")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/autocomplete/plates", "plateAutocomplete", `@GetMapping("/autocomplete/plates")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/autocomplete", "autocompletePlates", `@GetMapping("/autocomplete")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/autocomplete/types", "vehicleTypeAutocomplete", `@GetMapping("/autocomplete/types")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/autocomplete/types/global", "vehicleTypeAutocompleteGlobal", `@GetMapping("/autocomplete/types/global")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/bindings", "listBindingsOverview", `@GetMapping("/bindings")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/bindings/search/relationship", "searchByRelationship", `@GetMapping("/bindings/search/relationship")`),
		vehicleRoute(http.MethodPut, "/api/vehicles/:vehicleId", "updateVehicle", `@PutMapping("/{vehicleId}")`),
		vehicleRoute(http.MethodDelete, "/api/vehicles/:vehicleId", "deleteVehicle", `@DeleteMapping("/{vehicleId}")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/:vehicleId", "getVehicle", `@GetMapping("/{vehicleId}")`),
		vehicleRoute(http.MethodDelete, "/api/vehicles/license/:licensePlate", "deleteVehicleByLicense", `@DeleteMapping("/license/{licensePlate}")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/exists/:licensePlate", "licenseExists", `@GetMapping("/exists/{licensePlate}")`),
		vehicleRoute(http.MethodPost, "/api/vehicles/:vehicleId/drivers", "bindDriver", `@PostMapping("/{vehicleId}/drivers")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/:vehicleId/drivers", "listBindings", `@GetMapping("/{vehicleId}/drivers")`),
		vehicleRoute(http.MethodDelete, "/api/vehicles/bindings/:bindingId", "deleteBinding", `@DeleteMapping("/bindings/{bindingId}")`),
		vehicleRoute(http.MethodPut, "/api/vehicles/bindings/:bindingId", "updateBinding", `@PutMapping("/bindings/{bindingId}")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/bindings/:bindingId", "getBinding", `@GetMapping("/bindings/{bindingId}")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/drivers/:driverId/vehicles", "listByDriver", `@GetMapping("/drivers/{driverId}/vehicles")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/drivers/:driverId/records", "listVehicleRecordsByDriver", `@GetMapping("/drivers/{driverId}/records")`),
		vehicleRoute(http.MethodGet, "/api/vehicles/drivers/:driverId/vehicles/primary", "primaryBinding", `@GetMapping("/drivers/{driverId}/vehicles/primary")`),
	}
}

func systemRoute(method, path, operation, state string) RouteSpec {
	return RouteSpec{
		Method:         method,
		Path:           path,
		Domain:         "system",
		Operation:      operation,
		Controller:     "GoZeroSystemRoutes",
		SpringMapping:  "go-zero internal",
		MigrationState: state,
	}
}

func authRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "authentication", operation, "AuthController", mapping)
}

func vehicleRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "vehicles", operation, "VehicleInformationController", mapping)
}

func routeSpec(method, path, domain, operation, controller, mapping string) RouteSpec {
	return RouteSpec{
		Method:         method,
		Path:           path,
		Domain:         domain,
		Operation:      operation,
		Controller:     controller,
		SpringMapping:  mapping,
		MigrationState: "route-stubbed",
	}
}
