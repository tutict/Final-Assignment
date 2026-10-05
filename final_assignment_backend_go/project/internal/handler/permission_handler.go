package handler

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

type PermissionHandler struct {
	svc PermissionService
}

// NewPermissionHandler 构造函数
func NewPermissionHandler(svc PermissionService) *PermissionHandler {
	return &PermissionHandler{svc: svc}
}

// RegisterRoutes 注册路由
func (h *PermissionHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api/permissions")
	{
		api.POST("", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.CreatePermission)
		api.GET("", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.GetAllPermissions)
		api.GET("/name/:permissionName", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.GetPermissionByName)
		api.GET("/search", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByName)
		api.GET("/parent/:parentId", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByParent)
		api.GET("/search/code/prefix", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByCodePrefix)
		api.GET("/search/code/fuzzy", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByCodeFuzzy)
		api.GET("/search/name/prefix", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByNamePrefix)
		api.GET("/search/name/fuzzy", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByNameFuzzy)
		api.GET("/search/type", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByType)
		api.GET("/search/api-path", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByAPIPath)
		api.GET("/search/menu-path", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByMenuPath)
		api.GET("/search/visible", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByVisible)
		api.GET("/search/external", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByExternal)
		api.GET("/search/status", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.SearchPermissionsByStatus)
		api.GET("/:permissionId", h.RequireRole("ADMIN", "SUPER_ADMIN"), h.GetPermissionById)
		api.PUT("/:permissionId", h.RequireRole("ADMIN"), h.UpdatePermission)
		api.DELETE("/name/:permissionName", h.RequireRole("ADMIN"), h.DeletePermissionByName)
		api.DELETE("/:permissionId", h.RequireRole("ADMIN"), h.DeletePermissionById)
	}
}

// RequireRole 模拟角色鉴权（真实项目中应通过 JWT 中间件实现）
func (h *PermissionHandler) RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 这里可以读取 JWT 并验证角色（略）
		// 假设 userRole 从 context 获取
		if memberOfRole(c, roles...) {
			c.Next()
			return
		}

		c.JSON(http.StatusForbidden, gin.H{"error": "access denied"})
		c.Abort()
	}
}

// ---------- CRUD ----------

// CreatePermission POST /api/permissions?idempotencyKey=xxx
func (h *PermissionHandler) CreatePermission(c *gin.Context) {
	var perm domain.PermissionManagement
	if err := c.ShouldBindJSON(&perm); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	key := idempotencyKey(c)
	if key == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "idempotency key required"})
		return
	}

	if err := h.svc.CheckAndInsertIdempotency(key, &perm, "create"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, apiOK(perm))
}

// GetPermissionById GET /api/permissions/:permissionId
func (h *PermissionHandler) GetPermissionById(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("permissionId"))
	perm, err := h.svc.GetPermissionById(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.JSON(http.StatusOK, perm)
}

// GetAllPermissions GET /api/permissions
func (h *PermissionHandler) GetAllPermissions(c *gin.Context) {
	perms, err := h.svc.GetAllPermissions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, perms)
}

// GetPermissionByName GET /api/permissions/name/:permissionName
func (h *PermissionHandler) GetPermissionByName(c *gin.Context) {
	name := c.Param("permissionName")
	perm, err := h.svc.GetPermissionByName(name)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.JSON(http.StatusOK, perm)
}

// SearchPermissionsByName GET /api/permissions/search?name=xx
func (h *PermissionHandler) SearchPermissionsByName(c *gin.Context) {
	name := c.Query("name")
	perms, err := h.svc.GetPermissionsByNameLike(name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, perms)
}

// UpdatePermission PUT /api/permissions/:permissionId?idempotencyKey=xxx
func (h *PermissionHandler) UpdatePermission(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("permissionId"))
	var updated domain.PermissionManagement
	if err := c.ShouldBindJSON(&updated); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	key := idempotencyKey(c)
	if key == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "idempotency key required"})
		return
	}

	if err := h.svc.UpdatePermission(id, key, &updated); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updated)
}

// DeletePermissionById DELETE /api/permissions/:permissionId
func (h *PermissionHandler) DeletePermissionById(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("permissionId"))
	if err := h.svc.DeletePermission(id); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.Status(http.StatusNoContent)
}

// DeletePermissionByName DELETE /api/permissions/name/:permissionName
func (h *PermissionHandler) DeletePermissionByName(c *gin.Context) {
	name := c.Param("permissionName")
	if err := h.svc.DeletePermissionByName(name); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.Status(http.StatusNoContent)
}

func (h *PermissionHandler) SearchPermissionsByParent(c *gin.Context) {
	parentID, err := strconv.Atoi(c.Param("parentId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid parent id"})
		return
	}
	h.searchPermissions(c, func(item domain.PermissionManagement) bool {
		return item.ParentID != nil && *item.ParentID == parentID
	})
}

func (h *PermissionHandler) SearchPermissionsByCodePrefix(c *gin.Context) {
	query := c.Query("permissionCode")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool { return hasPrefixFold(item.PermissionCode, query) })
}

func (h *PermissionHandler) SearchPermissionsByCodeFuzzy(c *gin.Context) {
	query := c.Query("permissionCode")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool { return containsFold(item.PermissionCode, query) })
}

func (h *PermissionHandler) SearchPermissionsByNamePrefix(c *gin.Context) {
	query := c.Query("permissionName")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool { return hasPrefixFold(item.PermissionName, query) })
}

func (h *PermissionHandler) SearchPermissionsByNameFuzzy(c *gin.Context) {
	query := c.Query("permissionName")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool { return containsFold(item.PermissionName, query) })
}

func (h *PermissionHandler) SearchPermissionsByType(c *gin.Context) {
	query := c.Query("permissionType")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool { return strings.EqualFold(item.PermissionType, query) })
}

func (h *PermissionHandler) SearchPermissionsByAPIPath(c *gin.Context) {
	query := c.Query("apiPath")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool { return containsFold(item.APIPath, query) })
}

func (h *PermissionHandler) SearchPermissionsByMenuPath(c *gin.Context) {
	query := c.Query("menuPath")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool { return containsFold(item.MenuPath, query) })
}

func (h *PermissionHandler) SearchPermissionsByVisible(c *gin.Context) {
	want := strings.EqualFold(c.Query("isVisible"), "true")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool {
		return item.IsVisible != nil && *item.IsVisible == want
	})
}

func (h *PermissionHandler) SearchPermissionsByExternal(c *gin.Context) {
	want := strings.EqualFold(c.Query("isExternal"), "true")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool {
		return item.IsExternal != nil && *item.IsExternal == want
	})
}

func (h *PermissionHandler) SearchPermissionsByStatus(c *gin.Context) {
	query := c.Query("status")
	h.searchPermissions(c, func(item domain.PermissionManagement) bool { return strings.EqualFold(item.Status, query) })
}

func (h *PermissionHandler) searchPermissions(c *gin.Context, match func(domain.PermissionManagement) bool) {
	items, err := h.svc.GetAllPermissions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch permissions"})
		return
	}
	filtered := make([]domain.PermissionManagement, 0)
	for _, item := range items {
		if match(item) {
			filtered = append(filtered, item)
		}
	}
	c.JSON(http.StatusOK, filtered)
}
