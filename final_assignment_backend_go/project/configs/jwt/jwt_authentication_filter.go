package jwt

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/configs/auth"
)

// AuthenticationMiddleware 验证 JWT 并将用户信息注入 Gin 上下文
func AuthenticationMiddleware(tokenProvider *auth.TokenProvider) gin.HandlerFunc {
	return func(c *gin.Context) {
		jwt := getJwtFromRequest(c)
		log.Printf("[INFO] Extracted JWT from request: %v", jwt)

		if jwt != "" && tokenProvider.ValidateToken(jwt) {
			username, err := tokenProvider.GetUsernameFromToken(jwt)
			if err != nil {
				log.Printf("[WARN] Failed to extract username: %v", err)
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
				return
			}

			roles, err := tokenProvider.ExtractRoles(jwt)
			if err != nil {
				log.Printf("[WARN] Failed to extract roles: %v", err)
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
				return
			}

			log.Printf("[INFO] JWT validated. Username: %s, Roles: %v", username, roles)

			// 注入用户信息
			c.Set("username", username)
			c.Set("roles", roles)

			log.Printf("[INFO] Authentication set for user: %s", username)
			c.Next()
		} else {
			log.Printf("[WARN] Invalid or missing JWT in request: %s", c.Request.RequestURI)
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		}
	}
}

func getJwtFromRequest(c *gin.Context) string {
	bearer := c.GetHeader("Authorization")
	if bearer != "" && strings.HasPrefix(bearer, "Bearer ") {
		return strings.TrimPrefix(bearer, "Bearer ")
	}
	return ""
}
