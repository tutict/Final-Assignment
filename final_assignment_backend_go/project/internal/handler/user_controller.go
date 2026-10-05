package handler

import (
	"encoding/json"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

// UserManagementController 提供用户管理相关的 HTTP 接口
type UserManagementController struct {
	userService UserManagementService
	userRoles   UserRoleSource
}

type UserRoleSource interface {
	ListUserRoles() ([]domain.SysUserRole, error)
	CreateUserRole(*domain.SysUserRole) error
	UpdateUserRole(*domain.SysUserRole) error
	DeleteUserRole(int64) error
}

// NewUserManagementController 创建新的控制器实例
func NewUserManagementController(svc UserManagementService) *UserManagementController {
	return &UserManagementController{userService: svc}
}

func (c *UserManagementController) WithUserRoles(source UserRoleSource) *UserManagementController {
	c.userRoles = source
	return c
}

// RegisterRoutes 注册路由
func (c *UserManagementController) RegisterRoutes(r *gin.RouterGroup) {
	users := r.Group("/users")

	users.POST("", c.CreateUser)
	users.GET("/me", c.GetCurrentUser)
	users.PUT("/me", c.UpdateCurrentUser)
	users.PUT("/me/password", c.UpdatePassword)
	users.GET("", c.GetAllUsers)
	users.GET("/username/:username", c.GetUserByUsername)
	users.GET("/role/:roleName", c.GetUsersByRole)
	users.GET("/status/:status", c.GetUsersByStatus)
	users.DELETE("/username/:username", c.DeleteUserByUsername)
	users.GET("/autocomplete/usernames/me", c.GetUsernameSuggestions)
	users.GET("/autocomplete/statuses/me", c.GetStatusSuggestions)
	users.GET("/autocomplete/phone-numbers/me", c.GetPhoneSuggestions)
	users.GET("/role-bindings/search", c.SearchUserRoleBindings)
	users.GET("/role-bindings/by-role/:roleId", c.ListUserRolesByRole)
	users.GET("/role-bindings", c.ListUserRoleBindings)
	users.GET("/role-bindings/:relationId", c.GetUserRoleBinding)
	users.PUT("/role-bindings/:relationId", c.UpdateUserRoleBinding)
	users.DELETE("/roles/:relationId", c.DeleteUserRoleBinding)
	users.GET("/:userId/roles", c.ListUserRoles)
	users.POST("/:userId/roles", c.BindUserRole)
	users.GET("/:userId", c.GetUserByID)
	users.PUT("/:userId", c.UpdateUser)
	users.DELETE("/:userId", c.DeleteUser)
}

// --------------------------
// 控制器方法实现
// --------------------------

// CreateUser 创建用户（仅 ADMIN）
func (c *UserManagementController) CreateUser(ctx *gin.Context) {
	var user domain.UserManagement
	idempotencyKey := idempotencyKey(ctx)

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

	ctx.JSON(http.StatusCreated, apiOK(user))
}

// GetCurrentUser 获取当前登录用户
func (c *UserManagementController) GetCurrentUser(ctx *gin.Context) {
	username := ctx.GetString("username")
	if username == "" {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthenticated"})
		return
	}

	user, err := c.userService.GetUserByUsername(username)
	if err != nil || user == nil || user.UserID == 0 {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	ctx.JSON(http.StatusOK, user)
}

// UpdateCurrentUser 更新当前用户自己的资料，只改非空字段，避免把密码和账号状态写空。
func (c *UserManagementController) UpdateCurrentUser(ctx *gin.Context) {
	username := ctx.GetString("username")
	if username == "" {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthenticated"})
		return
	}

	var patch userProfilePatch
	if err := ctx.ShouldBindJSON(&patch); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	existing, err := c.userService.GetUserByUsername(username)
	if err != nil || existing == nil || existing.UserID == 0 {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	applyUserPatch(existing, patch, false)
	if err := c.userService.CheckAndInsertIdempotency(requestIdempotencyKey(ctx), existing, "update"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, existing)
}

// UpdatePassword 修改当前用户密码。前端按 text/plain 提交，也兼容 JSON 字符串。
func (c *UserManagementController) UpdatePassword(ctx *gin.Context) {
	username := ctx.GetString("username")
	if username == "" {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "unauthenticated"})
		return
	}

	raw, err := ctx.GetRawData()
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}
	password := normalizePlainPassword(string(raw))
	if len(password) < 8 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "密码至少 8 位"})
		return
	}

	user, err := c.userService.GetUserByUsername(username)
	if err != nil || user == nil || user.UserID == 0 {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	user.Password = password
	if err := c.userService.CheckAndInsertIdempotency(requestIdempotencyKey(ctx), user, "update"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx.Status(http.StatusNoContent)
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

// UpdateUser 更新指定用户（仅 ADMIN）。按字段合并，空密码不会覆盖原密码。
func (c *UserManagementController) UpdateUser(ctx *gin.Context) {
	userId := ctx.Param("userId")
	var patch userProfilePatch
	if err := ctx.ShouldBindJSON(&patch); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	existing, err := c.userService.GetUserByID(userId)
	if err != nil || existing == nil || existing.UserID == 0 {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	applyUserPatch(existing, patch, true)
	if err := c.userService.UpdateUserByID(userId, existing, requestIdempotencyKey(ctx)); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, existing)
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

type userProfilePatch struct {
	Username      *string `json:"username"`
	Password      *string `json:"password"`
	RealName      *string `json:"realName"`
	Email         *string `json:"email"`
	ContactNumber *string `json:"contactNumber"`
	PhoneNumber   *string `json:"phoneNumber"`
	Department    *string `json:"department"`
	Position      *string `json:"position"`
	Status        *string `json:"status"`
	Remarks       *string `json:"remarks"`
}

func requestIdempotencyKey(ctx *gin.Context) string {
	if key := strings.TrimSpace(ctx.GetHeader("Idempotency-Key")); key != "" {
		return key
	}
	return strings.TrimSpace(ctx.Query("idempotencyKey"))
}

func normalizePlainPassword(raw string) string {
	password := strings.TrimSpace(raw)
	if len(password) >= 2 && password[0] == '"' && password[len(password)-1] == '"' {
		var decoded string
		if err := json.Unmarshal([]byte(password), &decoded); err == nil {
			password = decoded
		} else {
			password = strings.Trim(password, `"`)
		}
	}
	return strings.TrimSpace(password)
}

func applyUserPatch(existing *domain.UserManagement, patch userProfilePatch, admin bool) {
	if admin {
		setIfText(&existing.Username, patch.Username)
		setIfText(&existing.Department, patch.Department)
		setIfText(&existing.Position, patch.Position)
		setIfText(&existing.Status, patch.Status)
		setIfText(&existing.Password, patch.Password)
	}
	setIfText(&existing.RealName, patch.RealName)
	setIfText(&existing.Email, patch.Email)
	phone := patch.ContactNumber
	if !hasText(phone) {
		phone = patch.PhoneNumber
	}
	if hasText(phone) && !strings.Contains(*phone, "*") {
		setIfText(&existing.ContactNumber, phone)
	}
	if patch.Remarks != nil && strings.TrimSpace(*patch.Remarks) != "" {
		existing.Remarks = strings.TrimSpace(*patch.Remarks)
	}
}

func setIfText(dest *string, src *string) {
	if !hasText(src) {
		return
	}
	*dest = strings.TrimSpace(*src)
}

func hasText(src *string) bool {
	return src != nil && strings.TrimSpace(*src) != ""
}

func (c *UserManagementController) ListUserRoles(ctx *gin.Context) {
	userID, err := strconv.Atoi(ctx.Param("userId"))
	if err != nil || userID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
		return
	}
	rows, err := c.roles()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.SysUserRole, 0)
	for _, row := range rows {
		if row.UserID == userID {
			filtered = append(filtered, row)
		}
	}
	ctx.JSON(http.StatusOK, filtered)
}

func (c *UserManagementController) BindUserRole(ctx *gin.Context) {
	userID, err := strconv.Atoi(ctx.Param("userId"))
	if err != nil || userID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
		return
	}
	var body struct {
		RoleID int `json:"roleId"`
	}
	if err := ctx.ShouldBindJSON(&body); err != nil || body.RoleID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "roleId is required"})
		return
	}
	if c.userRoles == nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "user role store is not configured"})
		return
	}
	row := domain.SysUserRole{UserID: userID, RoleID: body.RoleID}
	if err := c.userRoles.CreateUserRole(&row); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusCreated, row)
}

func (c *UserManagementController) ListUserRoleBindings(ctx *gin.Context) {
	rows, err := c.roles()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, rows)
}

func (c *UserManagementController) ListUserRolesByRole(ctx *gin.Context) {
	roleID, err := strconv.Atoi(ctx.Param("roleId"))
	if err != nil || roleID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid role id"})
		return
	}
	rows, err := c.roles()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.SysUserRole, 0)
	for _, row := range rows {
		if row.RoleID == roleID {
			filtered = append(filtered, row)
		}
	}
	ctx.JSON(http.StatusOK, filtered)
}

func (c *UserManagementController) SearchUserRoleBindings(ctx *gin.Context) {
	userID, err1 := strconv.Atoi(ctx.Query("userId"))
	roleID, err2 := strconv.Atoi(ctx.Query("roleId"))
	if err1 != nil || err2 != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "userId and roleId are required"})
		return
	}
	rows, err := c.roles()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.SysUserRole, 0)
	for _, row := range rows {
		if row.UserID == userID && row.RoleID == roleID {
			filtered = append(filtered, row)
		}
	}
	ctx.JSON(http.StatusOK, filtered)
}

func (c *UserManagementController) GetUserRoleBinding(ctx *gin.Context) {
	id, err := strconv.ParseInt(ctx.Param("relationId"), 10, 64)
	if err != nil || id <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid relation id"})
		return
	}
	rows, err := c.roles()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	for _, row := range rows {
		if row.ID == id {
			ctx.JSON(http.StatusOK, row)
			return
		}
	}
	ctx.JSON(http.StatusNotFound, gin.H{"error": "role binding not found"})
}

func (c *UserManagementController) UpdateUserRoleBinding(ctx *gin.Context) {
	id, err := strconv.ParseInt(ctx.Param("relationId"), 10, 64)
	if err != nil || id <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid relation id"})
		return
	}
	var body struct {
		UserID int `json:"userId"`
		RoleID int `json:"roleId"`
	}
	if err := ctx.ShouldBindJSON(&body); err != nil || body.RoleID <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "roleId is required"})
		return
	}
	if c.userRoles == nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "user role store is not configured"})
		return
	}
	row := domain.SysUserRole{ID: id, UserID: body.UserID, RoleID: body.RoleID}
	if err := c.userRoles.UpdateUserRole(&row); err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "role binding not found"})
		return
	}
	ctx.JSON(http.StatusOK, row)
}

func (c *UserManagementController) DeleteUserRoleBinding(ctx *gin.Context) {
	id, err := strconv.ParseInt(ctx.Param("relationId"), 10, 64)
	if err != nil || id <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid relation id"})
		return
	}
	if c.userRoles == nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "user role store is not configured"})
		return
	}
	if err := c.userRoles.DeleteUserRole(id); err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "role binding not found"})
		return
	}
	ctx.Status(http.StatusNoContent)
}

func (c *UserManagementController) roles() ([]domain.SysUserRole, error) {
	if c.userRoles == nil {
		return []domain.SysUserRole{}, nil
	}
	return c.userRoles.ListUserRoles()
}
