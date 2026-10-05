package handler

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

// RoleManagementController 提供角色管理的 HTTP 接口
type RoleManagementController struct {
	roleService     RoleManagementService
	rolePermissions RolePermissionSource
}

type RolePermissionSource interface {
	ListRolePermissions() ([]domain.SysRolePermission, error)
}

// NewRoleManagementController 创建新的角色管理控制器实例
func NewRoleManagementController(roleService RoleManagementService) *RoleManagementController {
	return &RoleManagementController{roleService: roleService}
}

func (ctrl *RoleManagementController) WithRolePermissions(source RolePermissionSource) *RoleManagementController {
	ctrl.rolePermissions = source
	return ctrl
}

// RegisterRoutes 注册角色相关的路由
func (ctrl *RoleManagementController) RegisterRoutes(router *gin.Engine) {
	roleGroup := router.Group("/api/roles")

	roleGroup.POST("", ctrl.CreateRole)                  // 创建角色
	roleGroup.GET("", ctrl.GetAllRoles)                  // 获取所有角色
	roleGroup.GET("/name/:roleName", ctrl.GetRoleByName) // 根据名称获取
	roleGroup.GET("/search", ctrl.GetRolesByNameLike)    // 模糊查询
	roleGroup.GET("/by-code/:roleCode", ctrl.GetRoleByCode)
	roleGroup.GET("/search/code/prefix", ctrl.SearchRolesByCodePrefix)
	roleGroup.GET("/search/code/fuzzy", ctrl.SearchRolesByCodeFuzzy)
	roleGroup.GET("/search/name/prefix", ctrl.SearchRolesByNamePrefix)
	roleGroup.GET("/search/name/fuzzy", ctrl.SearchRolesByNameFuzzy)
	roleGroup.GET("/search/type", ctrl.SearchRolesByType)
	roleGroup.GET("/search/data-scope", ctrl.SearchRolesByDataScope)
	roleGroup.GET("/search/status", ctrl.SearchRolesByStatus)
	roleGroup.GET("/permissions/search", ctrl.SearchRolePermissions)
	roleGroup.GET("/:roleId/permissions", ctrl.ListRolePermissions)
	roleGroup.DELETE("/name/:roleName", ctrl.DeleteRoleByName) // 删除角色（按名称）
	roleGroup.GET("/:roleId", ctrl.GetRoleById)                // 根据 ID 获取
	roleGroup.PUT("/:roleId", ctrl.UpdateRole)                 // 更新角色
	roleGroup.DELETE("/:roleId", ctrl.DeleteRole)              // 删除角色（按ID）
}

// CreateRole 创建新的角色记录（仅限 ADMIN）
func (ctrl *RoleManagementController) CreateRole(c *gin.Context) {
	var role domain.RoleManagement
	idempotencyKey := idempotencyKey(c)

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

	c.JSON(http.StatusCreated, apiOK(role))
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
	idempotencyKey := idempotencyKey(c)

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

	updatedRole.RoleID = existingRole.RoleID

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

func (ctrl *RoleManagementController) GetRoleByCode(c *gin.Context) {
	code := c.Param("roleCode")
	roles, err := ctrl.roleService.GetAllRoles()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch roles"})
		return
	}
	for _, role := range roles {
		if strings.EqualFold(role.RoleCode, code) {
			c.JSON(http.StatusOK, role)
			return
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"error": "role not found"})
}

func (ctrl *RoleManagementController) SearchRolesByCodePrefix(c *gin.Context) {
	query := c.Query("roleCode")
	ctrl.searchRoles(c, func(role domain.RoleManagement) bool { return hasPrefixFold(role.RoleCode, query) })
}

func (ctrl *RoleManagementController) SearchRolesByCodeFuzzy(c *gin.Context) {
	query := c.Query("roleCode")
	ctrl.searchRoles(c, func(role domain.RoleManagement) bool { return containsFold(role.RoleCode, query) })
}

func (ctrl *RoleManagementController) SearchRolesByNamePrefix(c *gin.Context) {
	query := c.Query("roleName")
	ctrl.searchRoles(c, func(role domain.RoleManagement) bool { return hasPrefixFold(role.RoleName, query) })
}

func (ctrl *RoleManagementController) SearchRolesByNameFuzzy(c *gin.Context) {
	query := c.Query("roleName")
	ctrl.searchRoles(c, func(role domain.RoleManagement) bool { return containsFold(role.RoleName, query) })
}

func (ctrl *RoleManagementController) SearchRolesByType(c *gin.Context) {
	query := c.Query("roleType")
	ctrl.searchRoles(c, func(role domain.RoleManagement) bool { return strings.EqualFold(role.RoleType, query) })
}

func (ctrl *RoleManagementController) SearchRolesByDataScope(c *gin.Context) {
	query := c.Query("dataScope")
	ctrl.searchRoles(c, func(role domain.RoleManagement) bool { return strings.EqualFold(role.DataScope, query) })
}

func (ctrl *RoleManagementController) SearchRolesByStatus(c *gin.Context) {
	query := c.Query("status")
	ctrl.searchRoles(c, func(role domain.RoleManagement) bool { return strings.EqualFold(role.Status, query) })
}

func (ctrl *RoleManagementController) searchRoles(c *gin.Context, match func(domain.RoleManagement) bool) {
	roles, err := ctrl.roleService.GetAllRoles()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch roles"})
		return
	}
	filtered := make([]domain.RoleManagement, 0)
	for _, role := range roles {
		if match(role) {
			filtered = append(filtered, role)
		}
	}
	c.JSON(http.StatusOK, filtered)
}

func (ctrl *RoleManagementController) ListRolePermissions(c *gin.Context) {
	roleID, err := strconv.Atoi(c.Param("roleId"))
	if err != nil || roleID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid role id"})
		return
	}
	rows, err := ctrl.permissions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.SysRolePermission, 0)
	for _, row := range rows {
		if row.RoleID == roleID {
			filtered = append(filtered, row)
		}
	}
	c.JSON(http.StatusOK, filtered)
}

func (ctrl *RoleManagementController) SearchRolePermissions(c *gin.Context) {
	roleID, err1 := strconv.Atoi(c.Query("roleId"))
	permissionID, err2 := strconv.Atoi(c.Query("permissionId"))
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "roleId and permissionId are required"})
		return
	}
	rows, err := ctrl.permissions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.SysRolePermission, 0)
	for _, row := range rows {
		if row.RoleID == roleID && row.PermissionID == permissionID {
			filtered = append(filtered, row)
		}
	}
	c.JSON(http.StatusOK, filtered)
}

func (ctrl *RoleManagementController) permissions() ([]domain.SysRolePermission, error) {
	if ctrl.rolePermissions == nil {
		return []domain.SysRolePermission{}, nil
	}
	return ctrl.rolePermissions.ListRolePermissions()
}
