package config

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// TokenProvider 等价于 Java 中的 TokenProvider
type TokenProvider struct {
	SecretKey string
}

// ValidateToken 解析并验证 JWT
func (tp *TokenProvider) ValidateToken(tokenString string) (*jwt.Token, error) {
	return jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// 确认签名算法
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return []byte(tp.SecretKey), nil
	})
}

// JwtAuthenticationMiddleware 等价于 JwtAuthenticationFilter
func JwtAuthenticationMiddleware(tp *TokenProvider) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Missing Authorization header"})
			return
		}

		// Bearer token 解析
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		token, err := tp.ValidateToken(tokenString)
		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			return
		}

		// 验证通过，继续请求
		c.Next()
	}
}

// RegisterSecurityRoutes 配置安全策略（等价于 SecurityFilterChain）
func RegisterSecurityRoutes(r *gin.Engine, tp *TokenProvider) {
	// 禁用 Gin 默认的 debug 输出
	gin.SetMode(gin.ReleaseMode)

	// 无状态认证（不使用 Session）
	r.Use(gin.Logger(), gin.Recovery())

	// 公开端点
	public := r.Group("/api")
	{
		public.POST("/auth/register", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "register ok"})
		})
		public.POST("/auth/login", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "login ok"})
		})
		public.POST("/auth/refresh", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "refresh ok"})
		})
		public.POST("/ai/chat", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "chat ok"})
		})
		public.POST("/users/me/password", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "password reset ok"})
		})
		public.GET("/actuator/health", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"status": "UP"})
		})
	}

	// 受保护端点
	protected := r.Group("/api")
	protected.Use(JwtAuthenticationMiddleware(tp))
	{
		protected.GET("/users/me", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "Authorized access"})
		})
	}
}

// InitSecurityServer 启动 HTTP 服务
func InitSecurityServer(secretKey string) {
	tp := &TokenProvider{SecretKey: secretKey}
	router := gin.Default()

	RegisterSecurityRoutes(router, tp)

	log.Println("Security-configured server running on :8080")
	err := router.Run(":8080")
	if err != nil {
		return
	}
}
