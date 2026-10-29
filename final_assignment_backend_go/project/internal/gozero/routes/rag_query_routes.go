package routes

import (
	"encoding/json"
	"net/http"

	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	"final_assignment_backend_go/project/internal/gozero/response"
	service "final_assignment_backend_go/project/internal/service/rag"

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
		// go-zero 服务是迁移脚手架，没有接入 JWT 鉴权：检索身份只能按匿名处理，
		// 也就是只有 PUBLIC 文档可见。请求体里的角色不参与判定。
		result, err := runtime.Query.Query(r.Context(), request, service.NewRagAccessContext("", nil))
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, result)
	}
}
