package handler

import (
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_front_go/project/internal/service"

	"final_assignment_front_go/project/internal/domain"
)

type AuthHandler struct {
	service *service.AuthWsService
	logger  *Logger
}

// Logger 自定义轻量日志器（可换成 zap、logrus）
type Logger struct {
	mu sync.Mutex
}

func (l *Logger) Info(msg string, args ...interface{}) {
	l.mu.Lock()
	defer l.mu.Unlock()
	logLine := time.Now().Format("2006-01-02 15:04:05") + " [INFO] " + fmt.Sprintf(msg, args...)
	fmt.Println(logLine)
}

func (l *Logger) Error(msg string, args ...interface{}) {
	l.mu.Lock()
	defer l.mu.Unlock()
	logLine := time.Now().Format("2006-01-02 15:04:05") + " [ERROR] " + fmt.Sprintf(msg, args...)
	fmt.Println(logLine)
}

func NewAuthHandler(s *service.AuthWsService) *AuthHandler {
	return &AuthHandler{service: s, logger: &Logger{}}
}

// Login POST /api/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req service.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil || req.Username == "" || req.Password == "" {
		h.logger.Error("Invalid login request")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username and password are required"})
		return
	}

	// 模拟异步逻辑
	go func() {
		h.logger.Info("Login request received for username: %s", req.Username)
	}()

	result, err := h.service.Login(req)
	if err != nil {
		h.logger.Error("Login failed for %s: %v", req.Username, err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	if token, ok := result["jwtToken"]; ok {
		h.logger.Info("Login success for %s", req.Username)
		c.JSON(http.StatusOK, gin.H{"jwtToken": token, "username": req.Username})
	} else {
		h.logger.Error("Login failed: invalid credentials for %s", req.Username)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
	}
}

// RegisterUser POST /api/auth/register
func (h *AuthHandler) RegisterUser(c *gin.Context) {
	var req service.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	h.logger.Info("Received register request for username: %s", req.Username)

	status, err := h.service.RegisterUser(req)
	if err != nil {
		h.logger.Error("Register failed for %s: %v", req.Username, err)
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"status": status})
}

// GetAllUsers GET /api/auth/users
// 注意：这里简化掉了 JWT 权限控制，可以配合 Gin 中间件实现
func (h *AuthHandler) GetAllUsers(c *gin.Context) {
	users, err := h.service.GetAllUsers()
	if err != nil {
		h.logger.Error("GetAllUsers failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	h.logger.Info("Fetched %d users successfully", len(users))
	c.JSON(http.StatusOK, users)
}
