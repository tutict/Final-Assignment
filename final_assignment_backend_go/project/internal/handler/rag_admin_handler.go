package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/zeromicro/go-zero/rest/pathvar"

	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	"final_assignment_backend_go/project/internal/gozero/routes"
)

// RegisterRagAdminRoutes 将 go-zero 运行时已实现的 RAG 管理路由桥接到 Gin 主应用，
// 路由契约与 /api/rag/admin 保持一致（对齐 Spring RagManagementController）。
func RegisterRagAdminRoutes(router *gin.Engine, runtime *gozerorag.Runtime) {
	router.GET("/api/rag/admin/overview", gin.WrapF(routes.RagOverviewHandler(runtime)))
	router.GET("/api/rag/admin/documents", gin.WrapF(routes.ListRagDocumentsHandler(runtime)))
	router.POST("/api/rag/admin/documents/upload", gin.WrapF(routes.UploadRagDocumentHandler(runtime)))
	router.POST("/api/rag/admin/documents/manual", gin.WrapF(routes.CreateManualRagDocumentHandler(runtime)))
	router.POST("/api/rag/admin/backfill", gin.WrapF(routes.RunRagBackfillHandler(runtime)))
	router.POST("/api/rag/admin/backfill/run", gin.WrapF(routes.RunRagBackfillBatchesHandler(runtime)))
	router.POST("/api/rag/admin/embedding/run", gin.WrapF(routes.RunRagEmbeddingBatchHandler(runtime)))
	router.POST("/api/rag/admin/embedding/requeue", gin.WrapF(routes.RequeueRagEmbeddingTasksHandler(runtime)))
	router.POST("/api/rag/admin/index/migrate", gin.WrapF(routes.MigrateRagIndexHandler(runtime)))
	router.DELETE("/api/rag/admin/documents/:documentId", ragDocumentDeleteHandler(runtime))
}

// ragDocumentDeleteHandler 注入 go-zero pathvar 上下文，复用 httpx.ParsePath 的路径参数解析。
func ragDocumentDeleteHandler(runtime *gozerorag.Runtime) gin.HandlerFunc {
	inner := routes.DeleteRagDocumentHandler(runtime)
	return func(c *gin.Context) {
		c.Request = pathvar.WithVars(c.Request, map[string]string{
			"documentId": c.Param("documentId"),
		})
		inner(c.Writer, c.Request)
	}
}
