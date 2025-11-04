package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

type PermissionHandler struct {
	svc *service.PermissionService
}

// NewPermissionHandler 构造函数
func NewPermissionHandler(svc *service.PermissionService) *PermissionHandler {
	return &PermissionHandler{svc: svc}
}

// RegisterRoutes 注册路由
func (h *PermissionHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api/permissions")
	{
		api.POST("", h.RequireRole("ADMIN"), h.CreatePermission)
		api.GET("/:permissionId", h.RequireRole("ADMIN", "USER"), h.GetPermissionById)
		api.GET("", h.RequireRole("ADMIN", "USER"), h.GetAllPermissions)
		api.GET("/name/:permissionName", h.RequireRole("ADMIN", "USER"), h.GetPermissionByName)
		api.GET("/search", h.RequireRole("ADMIN", "USER"), h.SearchPermissionsByName)
		api.PUT("/:permissionId", h.RequireRole("ADMIN"), h.UpdatePermission)
		api.DELETE("/:permissionId", h.RequireRole("ADMIN"), h.DeletePermissionById)
		api.DELETE("/name/:permissionName", h.RequireRole("ADMIN"), h.DeletePermissionByName)
	}
}

// RequireRole 模拟角色鉴权（真实项目中应通过 JWT 中间件实现）
func (h *PermissionHandler) RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 这里可以读取 JWT 并验证角色（略）
		// 假设 userRole 从 context 获取
		userRole := c.GetString("role")

		for _, role := range roles {
			if role == userRole {
				c.Next()
				return
			}
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

	key := c.Query("idempotencyKey")
	if key == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "idempotency key required"})
		return
	}

	if err := h.svc.CheckAndInsertIdempotency(key, &perm, "create"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusCreated)
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

	key := c.Query("idempotencyKey")
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
