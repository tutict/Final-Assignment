package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

// RoleManagementController 提供角色管理的 HTTP 接口
type RoleManagementController struct {
	roleService *service.RoleManagementService
}

// NewRoleManagementController 创建新的角色管理控制器实例
func NewRoleManagementController(roleService *service.RoleManagementService) *RoleManagementController {
	return &RoleManagementController{roleService: roleService}
}

// RegisterRoutes 注册角色相关的路由
func (ctrl *RoleManagementController) RegisterRoutes(router *gin.Engine) {
	roleGroup := router.Group("/api/roles")

	roleGroup.POST("", ctrl.CreateRole)                        // 创建角色
	roleGroup.GET("", ctrl.GetAllRoles)                        // 获取所有角色
	roleGroup.GET("/:roleId", ctrl.GetRoleById)                // 根据 ID 获取
	roleGroup.GET("/name/:roleName", ctrl.GetRoleByName)       // 根据名称获取
	roleGroup.GET("/search", ctrl.GetRolesByNameLike)          // 模糊查询
	roleGroup.PUT("/:roleId", ctrl.UpdateRole)                 // 更新角色
	roleGroup.DELETE("/:roleId", ctrl.DeleteRole)              // 删除角色（按ID）
	roleGroup.DELETE("/name/:roleName", ctrl.DeleteRoleByName) // 删除角色（按名称）
}

// CreateRole 创建新的角色记录（仅限 ADMIN）
func (ctrl *RoleManagementController) CreateRole(c *gin.Context) {
	var role domain.RoleManagement
	idempotencyKey := c.Query("idempotencyKey")

	if idempotencyKey == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "idempotencyKey is required"})
		return
	}

	if err := c.ShouldBindJSON(&role); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	if err := ctrl.roleService.CheckAndInsertIdempotency(idempotencyKey, &role, "create"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusCreated)
}

// GetRoleById 根据 ID 获取角色记录
func (ctrl *RoleManagementController) GetRoleById(c *gin.Context) {
	roleId := c.Param("roleId")

	role, err := ctrl.roleService.GetRoleById(roleId)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "role not found"})
		return
	}

	c.JSON(http.StatusOK, role)
}

// GetAllRoles 获取所有角色记录
func (ctrl *RoleManagementController) GetAllRoles(c *gin.Context) {
	roles, err := ctrl.roleService.GetAllRoles()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch roles"})
		return
	}

	c.JSON(http.StatusOK, roles)
}

// GetRoleByName 根据角色名称获取角色记录
func (ctrl *RoleManagementController) GetRoleByName(c *gin.Context) {
	roleName := c.Param("roleName")

	role, err := ctrl.roleService.GetRoleByName(roleName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "role not found"})
		return
	}

	c.JSON(http.StatusOK, role)
}

// GetRolesByNameLike 根据名称模糊搜索角色
func (ctrl *RoleManagementController) GetRolesByNameLike(c *gin.Context) {
	name := c.Query("name")
	if name == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter 'name' is required"})
		return
	}

	roles, err := ctrl.roleService.GetRolesByNameLike(name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to search roles"})
		return
	}

	c.JSON(http.StatusOK, roles)
}

// UpdateRole 更新角色记录（仅限 ADMIN）
func (ctrl *RoleManagementController) UpdateRole(c *gin.Context) {
	roleId := c.Param("roleId")
	idempotencyKey := c.Query("idempotencyKey")

	if idempotencyKey == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "idempotencyKey is required"})
		return
	}

	var updatedRole domain.RoleManagement
	if err := c.ShouldBindJSON(&updatedRole); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	existingRole, err := ctrl.roleService.GetRoleById(roleId)
	if err != nil || existingRole == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "role not found"})
		return
	}

	updatedRole.RoleId = existingRole.RoleId

	if err := ctrl.roleService.CheckAndInsertIdempotency(idempotencyKey, &updatedRole, "update"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updatedRole)
}

// DeleteRole 根据 ID 删除角色记录（仅限 ADMIN）
func (ctrl *RoleManagementController) DeleteRole(c *gin.Context) {
	roleId := c.Param("roleId")

	if err := ctrl.roleService.DeleteRole(roleId); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "role not found"})
		return
	}

	c.Status(http.StatusNoContent)
}

// DeleteRoleByName 根据角色名称删除角色记录（仅限 ADMIN）
func (ctrl *RoleManagementController) DeleteRoleByName(c *gin.Context) {
	roleName := c.Param("roleName")

	if err := ctrl.roleService.DeleteRoleByName(roleName); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "role not found"})
		return
	}

	c.Status(http.StatusNoContent)
}
