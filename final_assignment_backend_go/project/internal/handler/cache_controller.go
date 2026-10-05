package handler

import (
	"log"
	"net/http"

	redisconfig "final_assignment_backend_go/project/configs/redis"

	"github.com/gin-gonic/gin"
)

// CacheController matches Spring POST /api/cache/clear.
// The Flutter deduction page calls it after a list load; a 404 there used to wipe the table.
type CacheController struct{}

func NewCacheController() *CacheController { return &CacheController{} }

func (c *CacheController) RegisterRoutes(router *gin.Engine) {
	router.POST("/api/cache/clear", c.Clear)
}

func (c *CacheController) Clear(ctx *gin.Context) {
	if !HasCapability(ctx, CapStaffWrite) {
		ctx.JSON(http.StatusForbidden, gin.H{"error": "access denied"})
		return
	}
	if redis := redisconfig.Current(); redis != nil {
		if err := redis.ClearCachePrefix(); err != nil {
			log.Printf("[WARN] cache clear skipped: %v", err)
		}
	}
	ctx.Status(http.StatusNoContent)
}
