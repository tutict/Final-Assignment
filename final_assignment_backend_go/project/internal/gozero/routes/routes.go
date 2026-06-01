package routes

import (
	"net/http"
	"time"

	"final_assignment_backend_go/project/internal/gozero/contract"
	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	"final_assignment_backend_go/project/internal/gozero/response"

	"github.com/zeromicro/go-zero/rest"
)

type Option func(*registerOptions)

type registerOptions struct {
	ragRuntime *gozerorag.Runtime
}

func WithRAGRuntime(runtime *gozerorag.Runtime) Option {
	return func(options *registerOptions) {
		options.ragRuntime = runtime
	}
}

func Register(server *rest.Server, options ...Option) {
	var config registerOptions
	for _, option := range options {
		option(&config)
	}

	server.AddRoutes(systemRoutes())
	server.AddRoutes(stubRoutes(contract.AuthRouteSpecs()))
	server.AddRoutes(stubRoutes(contract.AdminRouteSpecs()))
	server.AddRoutes(stubRoutes(contract.VehicleRouteSpecs()))
	server.AddRoutes(stubRoutes(contract.BusinessRouteSpecs()))
	server.AddRoutes(stubRoutes(contract.AuditRouteSpecs()))
	server.AddRoutes(stubRoutes(contract.AiChatRouteSpecs()))
	server.AddRoutes(stubRoutes(contract.RagQueryRouteSpecs()))
	server.AddRoutes(ragAdminRoutes(config.ragRuntime))
}

func systemRoutes() []rest.Route {
	return []rest.Route{
		{
			Method:  http.MethodGet,
			Path:    "/actuator/health",
			Handler: healthHandler,
		},
		{
			Method:  http.MethodGet,
			Path:    "/api/health",
			Handler: healthHandler,
		},
		{
			Method:  http.MethodGet,
			Path:    "/api/contracts",
			Handler: contractsHandler,
		},
		{
			Method:  http.MethodGet,
			Path:    "/api/go-zero/contracts",
			Handler: contractsHandler,
		},
		{
			Method:  http.MethodGet,
			Path:    "/api/go-zero/routes",
			Handler: routeSpecsHandler,
		},
	}
}

func stubRoutes(specs []contract.RouteSpec) []rest.Route {
	routes := make([]rest.Route, 0, len(specs))
	for _, spec := range specs {
		routeSpec := spec
		routes = append(routes, rest.Route{
			Method:  routeSpec.Method,
			Path:    routeSpec.Path,
			Handler: stubHandler(routeSpec),
		})
	}
	return routes
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	response.OK(w, map[string]any{
		"status":    "UP",
		"service":   "final-assignment-go-api",
		"framework": "go-zero",
		"time":      time.Now().UTC().Format(time.RFC3339),
	})
}

func contractsHandler(w http.ResponseWriter, r *http.Request) {
	response.OK(w, contract.CurrentSnapshot())
}

func routeSpecsHandler(w http.ResponseWriter, r *http.Request) {
	response.OK(w, contract.RegisteredRouteSpecs())
}

func stubHandler(spec contract.RouteSpec) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		response.NotImplemented(w, map[string]any{
			"method":         spec.Method,
			"path":           spec.Path,
			"domain":         spec.Domain,
			"operation":      spec.Operation,
			"controller":     spec.Controller,
			"springMapping":  spec.SpringMapping,
			"migrationState": spec.MigrationState,
		})
	}
}
