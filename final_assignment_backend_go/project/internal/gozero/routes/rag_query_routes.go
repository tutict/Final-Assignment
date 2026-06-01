package routes

import (
	"encoding/json"
	"net/http"

	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	"final_assignment_backend_go/project/internal/gozero/response"
	"final_assignment_backend_go/project/internal/service"

	"github.com/zeromicro/go-zero/rest"
)

func ragQueryRoutes(runtime *gozerorag.Runtime) []rest.Route {
	return []rest.Route{
		{Method: http.MethodPost, Path: "/api/rag/query", Handler: ragQueryHandler(runtime)},
	}
}

func ragQueryHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var request service.RagQueryRequest
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			response.Error(w, http.StatusBadRequest, "INVALID_REQUEST", "request body is not valid JSON")
			return
		}
		if runtime == nil || runtime.Query == nil {
			response.OK(w, service.RagQueryResponse{Results: []service.RagRetrievalResult{}})
			return
		}
		result, err := runtime.Query.Query(r.Context(), request)
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, result)
	}
}
