package global_exception

import (
	"errors"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// 自定义错误类型（可选，用于模拟 Java 中的各种异常）
var (
	ErrResourceNotFound       = errors.New("资源未找到")
	ErrInvalidArgument        = errors.New("无效的请求参数")
	ErrUnauthorized           = errors.New("未经授权的访问")
	ErrForbidden              = errors.New("禁止访问")
	ErrDataIntegrityViolation = errors.New("数据完整性冲突")
	ErrValidationFailed       = errors.New("请求参数验证失败")
)

// GlobalExceptionHandler 中间件
func GlobalExceptionHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				// 捕获 panic（类似于 Exception.class）
				log.Printf("[ERROR] Panic recovered: %v", r)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "服务器内部错误"})
				return
			}
		}()

		c.Next() // 执行请求链

		// 检查是否有错误
		if len(c.Errors) > 0 {
			err := c.Errors.Last().Err
			handleError(c, err)
		}
	}
}

// handleError 将错误映射为 HTTP 状态码与消息
func handleError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrResourceNotFound):
		log.Printf("[WARN] Resource not found: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	case errors.Is(err, ErrInvalidArgument):
		log.Printf("[WARN] Invalid argument: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求参数: " + err.Error()})
	case errors.Is(err, ErrUnauthorized):
		log.Printf("[WARN] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未经授权的访问: " + err.Error()})
	case errors.Is(err, ErrForbidden):
		log.Printf("[WARN] Forbidden: %v", err)
		c.JSON(http.StatusForbidden, gin.H{"error": "禁止访问: " + err.Error()})
	case errors.Is(err, ErrDataIntegrityViolation):
		log.Printf("[WARN] Data integrity violation: %v", err)
		c.JSON(http.StatusConflict, gin.H{"error": "数据完整性冲突: " + err.Error()})
	case errors.Is(err, ErrValidationFailed):
		log.Printf("[WARN] Validation failed: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数验证失败: " + err.Error()})
	default:
		log.Printf("[ERROR] Generic exception: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "服务器内部错误: " + err.Error()})
	}
}
