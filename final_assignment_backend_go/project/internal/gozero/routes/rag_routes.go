package routes

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"final_assignment_backend_go/project/internal/domain"
	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	"final_assignment_backend_go/project/internal/gozero/response"

	"github.com/zeromicro/go-zero/rest"
	"github.com/zeromicro/go-zero/rest/httpx"
)

type manualRagDocumentRequest struct {
	SourceID      string `json:"sourceId"`
	SourceVersion string `json:"sourceVersion"`
	Title         string `json:"title"`
	Content       string `json:"content"`
	ACLScope      string `json:"aclScope"`
	Route         string `json:"route"`
	MetadataJSON  string `json:"metadataJson"`
}

type ragIndexResponse struct {
	Document           domain.RagDocument `json:"document"`
	ChunkCount         int                `json:"chunkCount"`
	EmbeddingTaskCount int                `json:"embeddingTaskCount"`
}

func ragAdminRoutes(runtime *gozerorag.Runtime) []rest.Route {
	return []rest.Route{
		{Method: http.MethodGet, Path: "/api/rag/admin/overview", Handler: ragOverviewHandler(runtime)},
		{Method: http.MethodGet, Path: "/api/rag/admin/documents", Handler: listRagDocumentsHandler(runtime)},
		{Method: http.MethodPost, Path: "/api/rag/admin/documents/upload", Handler: uploadRagDocumentHandler(runtime)},
		{Method: http.MethodPost, Path: "/api/rag/admin/documents/manual", Handler: createManualRagDocumentHandler(runtime)},
		{Method: http.MethodPost, Path: "/api/rag/admin/backfill", Handler: runRagBackfillHandler(runtime)},
		{Method: http.MethodPost, Path: "/api/rag/admin/backfill/run", Handler: runRagBackfillBatchesHandler(runtime)},
		{Method: http.MethodPost, Path: "/api/rag/admin/embedding/run", Handler: runRagEmbeddingBatchHandler(runtime)},
		{Method: http.MethodPost, Path: "/api/rag/admin/embedding/requeue", Handler: requeueRagEmbeddingTasksHandler(runtime)},
		{Method: http.MethodPost, Path: "/api/rag/admin/index/migrate", Handler: migrateRagIndexHandler(runtime)},
		{Method: http.MethodDelete, Path: "/api/rag/admin/documents/:documentId", Handler: deleteRagDocumentHandler(runtime)},
	}
}

func ragOverviewHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !runtime.Ready() {
			response.OK(w, map[string]any{
				"enabled":                     false,
				"indexingEnabled":             false,
				"documentCount":               0,
				"readyDocumentCount":          0,
				"chunkCount":                  0,
				"pendingEmbeddingTaskCount":   0,
				"failedEmbeddingTaskCount":    0,
				"succeededEmbeddingTaskCount": 0,
				"poisonedEmbeddingTaskCount":  0,
			})
			return
		}
		overview, err := runtime.Documents.Overview(r.Context())
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, overview)
	}
}

func listRagDocumentsHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireRAGRuntime(w, runtime, "RAG_DISABLED", "RAG document listing is not enabled") {
			return
		}
		limit, err := intQuery(r, "limit", 50, 200)
		if err != nil {
			badRequest(w, err)
			return
		}
		documents, err := runtime.Documents.List(r.Context(), r.URL.Query().Get("query"), limit)
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, documents)
	}
}

func uploadRagDocumentHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireIndexingRuntime(w, runtime, "RAG_DISABLED", "RAG indexing is not enabled") {
			return
		}
		if runtime.UploadParser == nil {
			response.Error(w, http.StatusConflict, "RAG_UPLOAD_DISABLED", "RAG upload parser is not configured")
			return
		}

		r.Body = http.MaxBytesReader(w, r.Body, runtime.UploadParser.MaxBytes()+1024*1024)
		if err := r.ParseMultipartForm(runtime.UploadParser.MaxBytes()); err != nil {
			response.Error(w, http.StatusBadRequest, "INVALID_RAG_UPLOAD", err.Error())
			return
		}
		file, header, err := r.FormFile("file")
		if err != nil {
			response.Error(w, http.StatusBadRequest, "INVALID_RAG_UPLOAD", "file is required")
			return
		}
		defer file.Close()

		parsedFile, err := runtime.UploadParser.Parse(file, header)
		if err != nil {
			response.Error(w, http.StatusBadRequest, "INVALID_RAG_UPLOAD", err.Error())
			return
		}
		if strings.TrimSpace(parsedFile.Content) == "" {
			response.Error(w, http.StatusBadRequest, "EMPTY_RAG_UPLOAD", "uploaded file did not contain indexable text")
			return
		}
		metadataJSON, err := mergeUploadMetadata(r.FormValue("metadataJson"), parsedFile)
		if err != nil {
			response.Error(w, http.StatusBadRequest, "INVALID_METADATA_JSON", err.Error())
			return
		}

		result, err := runtime.Indexing.Index(r.Context(), domain.RagSourceDocument{
			SourceType:    "UPLOAD",
			SourceTable:   "uploaded_rag_document",
			SourceID:      defaultString(r.FormValue("sourceId"), newSourceID("upload")),
			SourceVersion: defaultString(r.FormValue("sourceVersion"), newSourceVersion()),
			Title:         defaultString(r.FormValue("title"), parsedFile.Title),
			Content:       parsedFile.Content,
			ACLScope:      defaultString(r.FormValue("aclScope"), "PUBLIC"),
			Route:         defaultString(r.FormValue("route"), ""),
			MetadataJSON:  metadataJSON,
			SourceField:   "file",
		})
		if err != nil {
			serviceError(w, err)
			return
		}
		response.Created(w, ragIndexResponse{
			Document:           result.Document,
			ChunkCount:         len(result.Chunks),
			EmbeddingTaskCount: len(result.EmbeddingTasks),
		})
	}
}

func createManualRagDocumentHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireIndexingRuntime(w, runtime, "RAG_DISABLED", "RAG indexing is not enabled") {
			return
		}
		var request manualRagDocumentRequest
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			response.Error(w, http.StatusBadRequest, "INVALID_REQUEST", "request body is not valid JSON")
			return
		}
		if err := validateManualRequest(request); err != nil {
			response.Error(w, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
			return
		}
		metadataJSON, err := normalizeMetadataJSON(request.MetadataJSON)
		if err != nil {
			response.Error(w, http.StatusBadRequest, "INVALID_METADATA_JSON", err.Error())
			return
		}

		result, err := runtime.Indexing.Index(r.Context(), domain.RagSourceDocument{
			SourceType:    "MANUAL",
			SourceTable:   "manual_rag_document",
			SourceID:      defaultString(request.SourceID, newSourceID("manual")),
			SourceVersion: defaultString(request.SourceVersion, newSourceVersion()),
			Title:         strings.TrimSpace(request.Title),
			Content:       strings.TrimSpace(request.Content),
			ACLScope:      defaultString(request.ACLScope, "PUBLIC"),
			Route:         defaultString(request.Route, ""),
			MetadataJSON:  metadataJSON,
			SourceField:   "content",
		})
		if err != nil {
			serviceError(w, err)
			return
		}
		response.Created(w, ragIndexResponse{
			Document:           result.Document,
			ChunkCount:         len(result.Chunks),
			EmbeddingTaskCount: len(result.EmbeddingTasks),
		})
	}
}

func runRagBackfillHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireIndexingRuntime(w, runtime, "RAG_DISABLED", "RAG backfill is not enabled") {
			return
		}
		page, err := intQuery(r, "page", 1, 0)
		if err != nil {
			badRequest(w, err)
			return
		}
		size, err := intQuery(r, "size", 200, 500)
		if err != nil {
			badRequest(w, err)
			return
		}
		result, err := runtime.Backfill.RunBatch(r.Context(), page, size)
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, result)
	}
}

func runRagBackfillBatchesHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireIndexingRuntime(w, runtime, "RAG_DISABLED", "RAG backfill is not enabled") {
			return
		}
		startPage, err := intQuery(r, "startPage", 1, 0)
		if err != nil {
			badRequest(w, err)
			return
		}
		size, err := intQuery(r, "size", 200, 500)
		if err != nil {
			badRequest(w, err)
			return
		}
		maxPages, err := intQuery(r, "maxPages", 20, 50)
		if err != nil {
			badRequest(w, err)
			return
		}
		result, err := runtime.Backfill.RunBatches(r.Context(), startPage, size, maxPages)
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, result)
	}
}

func runRagEmbeddingBatchHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireEmbeddingRuntime(w, runtime) {
			return
		}
		limit, err := intQuery(r, "limit", 25, 500)
		if err != nil {
			badRequest(w, err)
			return
		}
		result, err := runtime.EmbeddingTasks.ProcessPendingBatch(r.Context(), limit)
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, result)
	}
}

func requeueRagEmbeddingTasksHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireMaintenanceRuntime(w, runtime) {
			return
		}
		limit, err := intQuery(r, "limit", 1000, 1000)
		if err != nil {
			badRequest(w, err)
			return
		}
		result, err := runtime.EmbeddingTasks.RequeueChunks(r.Context(), limit, time.Now().UTC())
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, result)
	}
}

func migrateRagIndexHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireMaintenanceRuntime(w, runtime) {
			return
		}
		requeue, err := boolQuery(r, "requeue", true)
		if err != nil {
			badRequest(w, err)
			return
		}
		requeueLimit, err := intQuery(r, "requeueLimit", 1000, 1000)
		if err != nil {
			badRequest(w, err)
			return
		}
		result, err := runtime.Migration.MigrateToNewIndex(r.Context(), r.URL.Query().Get("indexName"), requeue, requeueLimit)
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, result)
	}
}

func deleteRagDocumentHandler(runtime *gozerorag.Runtime) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireRAGRuntime(w, runtime, "RAG_DISABLED", "RAG document deletion is not enabled") {
			return
		}
		var request struct {
			DocumentID string `path:"documentId"`
		}
		if err := httpx.ParsePath(r, &request); err != nil || strings.TrimSpace(request.DocumentID) == "" {
			response.Error(w, http.StatusBadRequest, "INVALID_REQUEST", "documentId is required")
			return
		}
		result, err := runtime.Documents.DeleteDocumentTree(r.Context(), strings.TrimSpace(request.DocumentID))
		if err != nil {
			serviceError(w, err)
			return
		}
		response.OK(w, result)
	}
}

func requireRAGRuntime(w http.ResponseWriter, runtime *gozerorag.Runtime, code, message string) bool {
	if runtime == nil || !runtime.Ready() {
		response.Error(w, http.StatusConflict, code, message)
		return false
	}
	return true
}

func requireIndexingRuntime(w http.ResponseWriter, runtime *gozerorag.Runtime, code, message string) bool {
	if !requireRAGRuntime(w, runtime, code, message) {
		return false
	}
	if !runtime.Config.IndexingEnabled || runtime.Indexing == nil {
		response.Error(w, http.StatusConflict, code, message)
		return false
	}
	return true
}

func requireEmbeddingRuntime(w http.ResponseWriter, runtime *gozerorag.Runtime) bool {
	if !requireRAGRuntime(w, runtime, "RAG_EMBEDDING_DISABLED", "RAG embedding is not enabled") {
		return false
	}
	if !runtime.Config.EmbeddingEnabled || runtime.EmbeddingTasks == nil {
		response.Error(w, http.StatusConflict, "RAG_EMBEDDING_DISABLED", "RAG embedding is not enabled")
		return false
	}
	return true
}

func requireMaintenanceRuntime(w http.ResponseWriter, runtime *gozerorag.Runtime) bool {
	if !requireRAGRuntime(w, runtime, "RAG_MAINTENANCE_DISABLED", "RAG index maintenance is not enabled") {
		return false
	}
	if runtime.EmbeddingTasks == nil || runtime.Migration == nil {
		response.Error(w, http.StatusConflict, "RAG_MAINTENANCE_DISABLED", "RAG index maintenance is not enabled")
		return false
	}
	return true
}

func intQuery(r *http.Request, name string, fallback, max int) (int, error) {
	raw := strings.TrimSpace(r.URL.Query().Get(name))
	if raw == "" {
		return clampPositive(fallback, max), nil
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return 0, fmt.Errorf("%s must be an integer", name)
	}
	return clampPositive(value, max), nil
}

func boolQuery(r *http.Request, name string, fallback bool) (bool, error) {
	raw := strings.TrimSpace(r.URL.Query().Get(name))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseBool(raw)
	if err != nil {
		return false, fmt.Errorf("%s must be a boolean", name)
	}
	return value, nil
}

func clampPositive(value, max int) int {
	if value < 1 {
		value = 1
	}
	if max > 0 && value > max {
		return max
	}
	return value
}

func validateManualRequest(request manualRagDocumentRequest) error {
	if strings.TrimSpace(request.Title) == "" {
		return fmt.Errorf("title must not be blank")
	}
	if utf8.RuneCountInString(request.Title) > 200 {
		return fmt.Errorf("title must be at most 200 characters")
	}
	if strings.TrimSpace(request.Content) == "" {
		return fmt.Errorf("content must not be blank")
	}
	if utf8.RuneCountInString(request.Content) > 20000 {
		return fmt.Errorf("content must be at most 20000 characters")
	}
	return nil
}

func normalizeMetadataJSON(value string) (string, error) {
	value = defaultString(value, "{}")
	var metadata map[string]any
	if err := json.Unmarshal([]byte(value), &metadata); err != nil {
		return "", fmt.Errorf("metadataJson is not valid JSON")
	}
	if metadata == nil {
		return "", fmt.Errorf("metadataJson must be a JSON object")
	}
	normalized, err := json.Marshal(metadata)
	if err != nil {
		return "", fmt.Errorf("metadataJson is not valid JSON")
	}
	return string(normalized), nil
}

func mergeUploadMetadata(value string, parsedFile gozerorag.ParsedRagFile) (string, error) {
	normalized, err := normalizeMetadataJSON(value)
	if err != nil {
		return "", err
	}
	var metadata map[string]any
	if err := json.Unmarshal([]byte(normalized), &metadata); err != nil {
		return "", fmt.Errorf("metadataJson is not valid JSON")
	}
	metadata["ingestMode"] = "upload"
	metadata["fileName"] = parsedFile.FileName
	metadata["contentType"] = defaultString(parsedFile.ContentType, "application/octet-stream")
	metadata["fileSize"] = parsedFile.Size
	metadata["parser"] = parsedFile.Parser
	if parsedFile.RowCount > 0 {
		metadata["rowCount"] = parsedFile.RowCount
	}
	if parsedFile.SheetCount > 0 {
		if strings.EqualFold(parsedFile.Parser, "pdf") {
			metadata["pageCount"] = parsedFile.SheetCount
		} else {
			metadata["sheetCount"] = parsedFile.SheetCount
		}
	}
	output, err := json.Marshal(metadata)
	if err != nil {
		return "", fmt.Errorf("metadataJson is not valid JSON")
	}
	return string(output), nil
}

func defaultString(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return strings.TrimSpace(value)
}

func newSourceID(prefix string) string {
	return fmt.Sprintf("%s-%d", prefix, time.Now().UnixNano())
}

func newSourceVersion() string {
	return fmt.Sprintf("v%d", time.Now().UnixMilli())
}

func badRequest(w http.ResponseWriter, err error) {
	response.Error(w, http.StatusBadRequest, "INVALID_REQUEST", err.Error())
}

func serviceError(w http.ResponseWriter, err error) {
	response.Error(w, http.StatusInternalServerError, "RAG_SERVICE_ERROR", err.Error())
}
