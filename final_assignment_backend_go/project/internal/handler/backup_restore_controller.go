package handler

import (
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
)

// BackupRestoreController 控制器层
type BackupRestoreController struct {
	backupService BackupRestoreService
}

// NewBackupRestoreController 创建控制器实例
func NewBackupRestoreController(backupService BackupRestoreService) *BackupRestoreController {
	return &BackupRestoreController{
		backupService: backupService,
	}
}

// RegisterRoutes 注册路由
func (c *BackupRestoreController) RegisterRoutes(r *gin.Engine) {
	c.mountBackups(r.Group("/api/backups"))
	c.mountBackups(r.Group("/api/system/backup"))
}

func (c *BackupRestoreController) mountBackups(group *gin.RouterGroup) {
	group.POST("", c.CreateBackup)
	group.GET("", c.GetAllBackups)
	group.GET("/filename/:backupFileName", c.GetBackupByFileName)
	group.GET("/time/:backupTime", c.GetBackupsByTime)
	group.GET("/search/type", c.SearchBackupsByType)
	group.GET("/search/file-name", c.SearchBackupsByFileName)
	group.GET("/search/handler", c.SearchBackupsByHandler)
	group.GET("/search/restore-status", c.SearchBackupsByRestoreStatus)
	group.GET("/search/status", c.SearchBackupsByStatus)
	group.GET("/search/backup-time-range", c.SearchBackupsByBackupTime)
	group.GET("/search/restore-time-range", c.SearchBackupsByRestoreTime)
	group.GET("/:backupId", c.GetBackupById)
	group.DELETE("/:backupId", c.DeleteBackup)
	group.PUT("/:backupId", c.UpdateBackup)
}

// CreateBackup 创建新的备份记录
func (c *BackupRestoreController) CreateBackup(ctx *gin.Context) {
	var backup domain.BackupRestore
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&backup); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	log.Printf("Attempting to create backup with idempotency key: %s", idempotencyKey)
	if err := c.backupService.CheckAndInsertIdempotency(idempotencyKey, &backup, "create"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log.Println("Backup created successfully.")
	ctx.Status(http.StatusCreated)
}

// GetAllBackups 获取所有备份记录
func (c *BackupRestoreController) GetAllBackups(ctx *gin.Context) {
	log.Println("Fetching all backups.")
	backups, err := c.backupService.GetAllBackups()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	log.Printf("Total backups found: %d", len(backups))
	ctx.JSON(http.StatusOK, backups)
}

// GetBackupById 根据ID获取备份记录
func (c *BackupRestoreController) GetBackupById(ctx *gin.Context) {
	backupId := ctx.Param("backupId")
	log.Printf("Fetching backup by ID: %s", backupId)

	backup, err := c.backupService.GetBackupById(backupId)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "backup not found"})
		return
	}
	ctx.JSON(http.StatusOK, backup)
}

// DeleteBackup 删除备份记录
func (c *BackupRestoreController) DeleteBackup(ctx *gin.Context) {
	backupId := ctx.Param("backupId")
	log.Printf("Attempting to delete backup with ID: %s", backupId)

	if err := c.backupService.DeleteBackup(backupId); err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "backup not found"})
		return
	}
	log.Println("Backup deleted successfully.")
	ctx.Status(http.StatusNoContent)
}

// UpdateBackup 更新备份记录
func (c *BackupRestoreController) UpdateBackup(ctx *gin.Context) {
	backupId := ctx.Param("backupId")
	idempotencyKey := ctx.Query("idempotencyKey")

	var updatedBackup domain.BackupRestore
	if err := ctx.ShouldBindJSON(&updatedBackup); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	log.Printf("Attempting to update backup with ID: %s", backupId)

	existingBackup, err := c.backupService.GetBackupById(backupId)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "backup not found"})
		return
	}

	updatedBackup.BackupID = existingBackup.BackupID
	if err := c.backupService.CheckAndInsertIdempotency(idempotencyKey, &updatedBackup, "update"); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log.Println("Backup updated successfully.")
	ctx.Status(http.StatusOK)
}

// GetBackupByFileName 根据文件名获取备份记录
func (c *BackupRestoreController) GetBackupByFileName(ctx *gin.Context) {
	backupFileName := ctx.Param("backupFileName")
	log.Printf("Fetching backup by file name: %s", backupFileName)

	backup, err := c.backupService.GetBackupByFileName(backupFileName)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "backup not found"})
		return
	}
	ctx.JSON(http.StatusOK, backup)
}

// GetBackupsByTime 根据备份时间获取备份记录
func (c *BackupRestoreController) GetBackupsByTime(ctx *gin.Context) {
	backupTime := ctx.Param("backupTime")
	log.Printf("Fetching backups by time: %s", backupTime)

	// 尝试解析时间格式
	parsedTime, err := time.Parse("2006-01-02T15:04:05", backupTime)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}

	backups, err := c.backupService.GetBackupsByTime(parsedTime)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, backups)
}

func (c *BackupRestoreController) SearchBackupsByType(ctx *gin.Context) {
	query := ctx.Query("backupType")
	c.searchBackups(ctx, func(item domain.BackupRestore) bool {
		return strings.EqualFold(item.BackupType, query)
	})
}

func (c *BackupRestoreController) SearchBackupsByFileName(ctx *gin.Context) {
	query := ctx.Query("backupFileName")
	c.searchBackups(ctx, func(item domain.BackupRestore) bool {
		return containsFold(item.BackupFileName, query)
	})
}

func (c *BackupRestoreController) SearchBackupsByHandler(ctx *gin.Context) {
	query := ctx.Query("backupHandler")
	c.searchBackups(ctx, func(item domain.BackupRestore) bool {
		return containsFold(item.BackupHandler, query)
	})
}

func (c *BackupRestoreController) SearchBackupsByRestoreStatus(ctx *gin.Context) {
	query := ctx.Query("restoreStatus")
	c.searchBackups(ctx, func(item domain.BackupRestore) bool {
		return strings.EqualFold(item.RestoreStatus, query)
	})
}

func (c *BackupRestoreController) SearchBackupsByStatus(ctx *gin.Context) {
	query := ctx.Query("status")
	c.searchBackups(ctx, func(item domain.BackupRestore) bool {
		return strings.EqualFold(item.Status, query)
	})
}

func (c *BackupRestoreController) SearchBackupsByBackupTime(ctx *gin.Context) {
	start, end, err := queryTimeWindow(ctx)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}
	c.searchBackups(ctx, func(item domain.BackupRestore) bool {
		return !item.BackupTime.Before(start) && !item.BackupTime.After(end)
	})
}

func (c *BackupRestoreController) SearchBackupsByRestoreTime(ctx *gin.Context) {
	start, end, err := queryTimeWindow(ctx)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid time format"})
		return
	}
	c.searchBackups(ctx, func(item domain.BackupRestore) bool {
		return item.RestoreTime != nil && !item.RestoreTime.Before(start) && !item.RestoreTime.After(end)
	})
}

func (c *BackupRestoreController) searchBackups(ctx *gin.Context, match func(domain.BackupRestore) bool) {
	rows, err := c.backupService.GetAllBackups()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	filtered := make([]domain.BackupRestore, 0)
	for _, row := range rows {
		if match(row) {
			filtered = append(filtered, row)
		}
	}
	ctx.JSON(http.StatusOK, filtered)
}
