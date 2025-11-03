package handler

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_front_go/project/internal/domain"
	"final_assignment_front_go/project/internal/service"
)

// BackupRestoreController 控制器层
type BackupRestoreController struct {
	backupService *service.BackupRestoreService
}

// NewBackupRestoreController 创建控制器实例
func NewBackupRestoreController(backupService *service.BackupRestoreService) *BackupRestoreController {
	return &BackupRestoreController{
		backupService: backupService,
	}
}

// RegisterRoutes 注册路由
func (c *BackupRestoreController) RegisterRoutes(r *gin.Engine) {
	group := r.Group("/api/backups")

	group.POST("", c.CreateBackup)
	group.GET("", c.GetAllBackups)
	group.GET("/:backupId", c.GetBackupById)
	group.DELETE("/:backupId", c.DeleteBackup)
	group.PUT("/:backupId", c.UpdateBackup)
	group.GET("/filename/:backupFileName", c.GetBackupByFileName)
	group.GET("/time/:backupTime", c.GetBackupsByTime)
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
