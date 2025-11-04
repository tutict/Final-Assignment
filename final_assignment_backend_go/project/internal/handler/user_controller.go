package handler

import (
	"encoding/json"
	"net/http"
	"net/url"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

// UserManagementController 提供用户管理相关的 HTTP 接口
type UserManagementController struct {
	userService *service.UserManagementService
}

// NewUserManagementController 创建新的控制器实例
func NewUserManagementController(svc *service.UserManagementService) *UserManagementController {
	return &UserManagementController{userService: svc}
}

// RegisterRoutes 注册路由
func (c *UserManagementController) RegisterRoutes(r *gin.RouterGroup) {
	users := r.Group("/users")

	users.POST("", c.CreateUser)
	users.GET("/me", c.GetCurrentUser)
	users.PUT("/me", c.UpdateCurrentUser)
	users.PUT("/me/password", c.UpdatePassword)
	users.GET("", c.GetAllUsers)
	users.GET("/:userId", c.GetUserByID)
	users.GET("/username/:username", c.GetUserByUsername)
	users.GET("/role/:roleName", c.GetUsersByRole)
	users.GET("/status/:status", c.GetUsersByStatus)
	users.PUT("/:userId", c.UpdateUser)
	users.DELETE("/:userId", c.DeleteUser)
	users.DELETE("/username/:username", c.DeleteUserByUsername)
	users.GET("/autocomplete/usernames/me", c.GetUsernameSuggestions)
	users.GET("/autocomplete/statuses/me", c.GetStatusSuggestions)
	users.GET("/autocomplete/phone-numbers/me", c.GetPhoneSuggestions)
}

// --------------------------
// 控制器方法实现
// --------------------------

// CreateUser 创建用户（仅 ADMIN）
func (c *UserManagementController) CreateUser(ctx *gin.Context) {
	var user domain.UserManagement
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&user); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	if c.userService.IsUsernameExists(user.Username) {
		ctx.JSON(http.StatusConflict, gin.H{"error": "username already exists"})
		return
	}

	if err := c.userService.CheckAndInsertIdempotency(idempotencyKey, &user, "create"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx.Status(http.StatusCreated)
}

// GetCurrentUser 获取当前登录用户
func (c *UserManagementController) GetCurrentUser(ctx *gin.Context) {
	username := ctx.GetString("username") // 从JWT中提取
	if username == "" {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthenticated"})
		return
	}

	user, err := c.userService.GetUserByUsername(username)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	ctx.JSON(http.StatusOK, user)
}

// UpdateCurrentUser 更新当前用户信息
func (c *UserManagementController) UpdateCurrentUser(ctx *gin.Context) {
	username := ctx.GetString("username")
	if username == "" {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthenticated"})
		return
	}

	var updated domain.UserManagement
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&updated); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	existing, err := c.userService.GetUserByUsername(username)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	updated.UserID = existing.UserID
	if err := c.userService.CheckAndInsertIdempotency(idempotencyKey, &updated, "update"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx.Status(http.StatusOK)
}

// UpdatePassword 更新当前用户密码
func (c *UserManagementController) UpdatePassword(ctx *gin.Context) {
	username := ctx.GetString("username")
	if username == "" {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthenticated"})
		return
	}

	var raw string
	if err := ctx.ShouldBindJSON(&raw); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	var password string
	if err := json.Unmarshal([]byte(raw), &password); err != nil {
		password = strings.Trim(raw, `"`)
	}

	idempotencyKey := ctx.Query("idempotencyKey")

	user, err := c.userService.GetUserByUsername(username)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	user.Password = password
	if err := c.userService.CheckAndInsertIdempotency(idempotencyKey, user, "update"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx.Status(http.StatusOK)
}

// GetAllUsers 获取所有用户
func (c *UserManagementController) GetAllUsers(ctx *gin.Context) {
	users, err := c.userService.GetAllUsers()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, users)
}

// GetUserByID 根据ID获取用户
func (c *UserManagementController) GetUserByID(ctx *gin.Context) {
	userId := ctx.Param("userId")
	user, err := c.userService.GetUserByID(userId)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	ctx.JSON(http.StatusOK, user)
}

// GetUserByUsername 根据用户名获取用户
func (c *UserManagementController) GetUserByUsername(ctx *gin.Context) {
	username := ctx.Param("username")
	user, err := c.userService.GetUserByUsername(username)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	ctx.JSON(http.StatusOK, user)
}

// GetUsersByRole 根据角色获取用户
func (c *UserManagementController) GetUsersByRole(ctx *gin.Context) {
	role := ctx.Param("roleName")
	users, err := c.userService.GetUsersByRole(role)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, users)
}

// GetUsersByStatus 根据状态获取用户
func (c *UserManagementController) GetUsersByStatus(ctx *gin.Context) {
	status := ctx.Param("status")
	users, err := c.userService.GetUsersByStatus(status)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, users)
}

// UpdateUser 更新指定用户（仅 ADMIN）
func (c *UserManagementController) UpdateUser(ctx *gin.Context) {
	userId := ctx.Param("userId")
	var updated domain.UserManagement
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&updated); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	if err := c.userService.UpdateUserByID(userId, &updated, idempotencyKey); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx.Status(http.StatusOK)
}

// DeleteUser 删除用户（按ID）
func (c *UserManagementController) DeleteUser(ctx *gin.Context) {
	userId := ctx.Param("userId")
	if err := c.userService.DeleteUserByID(userId); err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	ctx.Status(http.StatusNoContent)
}

// DeleteUserByUsername 删除用户（按用户名）
func (c *UserManagementController) DeleteUserByUsername(ctx *gin.Context) {
	username := ctx.Param("username")
	if err := c.userService.DeleteUserByUsername(username); err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	ctx.Status(http.StatusNoContent)
}

// GetUsernameSuggestions Autocomplete 功能
func (c *UserManagementController) GetUsernameSuggestions(ctx *gin.Context) {
	prefix, _ := url.QueryUnescape(ctx.Query("prefix"))
	list, err := c.userService.GetUsernamesByPrefixGlobally(prefix)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, list)
}

func (c *UserManagementController) GetStatusSuggestions(ctx *gin.Context) {
	prefix, _ := url.QueryUnescape(ctx.Query("prefix"))
	list, err := c.userService.GetStatusesByPrefixGlobally(prefix)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, list)
}

func (c *UserManagementController) GetPhoneSuggestions(ctx *gin.Context) {
	prefix, _ := url.QueryUnescape(ctx.Query("prefix"))
	list, err := c.userService.GetPhoneNumbersByPrefixGlobally(prefix)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, list)
}
