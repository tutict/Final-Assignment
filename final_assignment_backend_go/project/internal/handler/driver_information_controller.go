package handler

import (
	"final_assignment_front_go/project/internal/domain"
	"final_assignment_front_go/project/internal/service"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type DriverInformationController struct {
	driverService *service.DriverInformationService
	userService   *service.UserManagementService
}

// NewDriverInformationController 构造函数
func NewDriverInformationController(
	driverService *service.DriverInformationService,
	userService *service.UserManagementService,
) *DriverInformationController {
	return &DriverInformationController{
		driverService: driverService,
		userService:   userService,
	}
}

// RegisterRoutes 注册路由
func (c *DriverInformationController) RegisterRoutes(r *gin.Engine) {
	group := r.Group("/api/drivers")

	group.POST("", c.CreateDriver)
	group.GET("", c.GetAllDrivers)
	group.GET("/:driverId", c.GetDriverById)
	group.PUT("/:driverId", c.UpdateDriver)
	group.PUT("/:driverId/name", c.UpdateDriverName)
	group.PUT("/:driverId/contactNumber", c.UpdateDriverContactNumber)
	group.PUT("/:driverId/idCardNumber", c.UpdateDriverIdCardNumber)
	group.DELETE("/:driverId", c.DeleteDriver)

	group.GET("/by-id-card", c.SearchByIdCardNumber)
	group.GET("/by-license-number", c.SearchByLicenseNumber)
	group.GET("/by-name", c.SearchByName)
}

// CreateDriver 创建司机信息
func (c *DriverInformationController) CreateDriver(ctx *gin.Context) {
	var driver domain.DriverInformation
	idempotencyKey := ctx.Query("idempotencyKey")

	if err := ctx.ShouldBindJSON(&driver); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	if err := c.driverService.CheckAndInsertIdempotency(idempotencyKey, &driver, "create"); err != nil {
		if err.Error() == "Duplicate request" {
			ctx.JSON(http.StatusConflict, gin.H{"error": "duplicate request"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.Status(http.StatusCreated)
}

// GetDriverById 根据ID获取司机信息
func (c *DriverInformationController) GetDriverById(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("driverId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid driver id"})
		return
	}

	driver, err := c.driverService.GetDriverById(id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "driver not found"})
		return
	}
	ctx.JSON(http.StatusOK, driver)
}

// GetAllDrivers 获取所有司机信息
func (c *DriverInformationController) GetAllDrivers(ctx *gin.Context) {
	drivers, err := c.driverService.GetAllDrivers()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, drivers)
}

// UpdateDriver 更新司机完整信息
func (c *DriverInformationController) UpdateDriver(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("driverId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid driver id"})
		return
	}
	idempotencyKey := ctx.Query("idempotencyKey")

	var updated domain.DriverInformation
	if err := ctx.ShouldBindJSON(&updated); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	updated.DriverId = id
	if err := c.driverService.CheckAndInsertIdempotency(idempotencyKey, &updated, "update"); err != nil {
		if err.Error() == "Duplicate request" {
			ctx.JSON(http.StatusConflict, gin.H{"error": "duplicate request"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.updateUserModifiedTime(id)
	ctx.Status(http.StatusNoContent)
}

// UpdateDriverName 更新司机姓名
func (c *DriverInformationController) UpdateDriverName(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("driverId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid driver id"})
		return
	}
	idempotencyKey := ctx.Query("idempotencyKey")

	var payload struct {
		Name string `json:"name"`
	}
	if err := ctx.ShouldBindJSON(&payload); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	driver, err := c.driverService.GetDriverById(id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "driver not found"})
		return
	}
	driver.Name = payload.Name

	if err := c.driverService.CheckAndInsertIdempotency(idempotencyKey, driver, "update"); err != nil {
		if err.Error() == "Duplicate request" {
			ctx.JSON(http.StatusConflict, gin.H{"error": "duplicate request"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.updateUserModifiedTime(id)
	ctx.Status(http.StatusNoContent)
}

// UpdateDriverContactNumber 更新司机联系电话
func (c *DriverInformationController) UpdateDriverContactNumber(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("driverId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid driver id"})
		return
	}
	idempotencyKey := ctx.Query("idempotencyKey")

	var payload struct {
		ContactNumber string `json:"contactNumber"`
	}
	if err := ctx.ShouldBindJSON(&payload); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	driver, err := c.driverService.GetDriverById(id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "driver not found"})
		return
	}
	driver.ContactNumber = payload.ContactNumber

	if err := c.driverService.CheckAndInsertIdempotency(idempotencyKey, driver, "update"); err != nil {
		if err.Error() == "Duplicate request" {
			ctx.JSON(http.StatusConflict, gin.H{"error": "duplicate request"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.updateUserModifiedTime(id)
	ctx.Status(http.StatusNoContent)
}

// UpdateDriverIdCardNumber 更新司机身份证号码
func (c *DriverInformationController) UpdateDriverIdCardNumber(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("driverId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid driver id"})
		return
	}
	idempotencyKey := ctx.Query("idempotencyKey")

	var payload struct {
		IdCardNumber string `json:"idCardNumber"`
	}
	if err := ctx.ShouldBindJSON(&payload); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid input"})
		return
	}

	driver, err := c.driverService.GetDriverById(id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "driver not found"})
		return
	}
	driver.IdCardNumber = payload.IdCardNumber

	if err := c.driverService.CheckAndInsertIdempotency(idempotencyKey, driver, "update"); err != nil {
		if err.Error() == "Duplicate request" {
			ctx.JSON(http.StatusConflict, gin.H{"error": "duplicate request"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.updateUserModifiedTime(id)
	ctx.Status(http.StatusNoContent)
}

// DeleteDriver 删除司机信息
func (c *DriverInformationController) DeleteDriver(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("driverId"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid driver id"})
		return
	}

	if err := c.driverService.DeleteDriver(id); err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "driver not found"})
		return
	}
	ctx.Status(http.StatusNoContent)
}

// SearchByIdCardNumber 按身份证号搜索
func (c *DriverInformationController) SearchByIdCardNumber(ctx *gin.Context) {
	query := ctx.Query("query")
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(ctx.DefaultQuery("size", "10"))

	results, err := c.driverService.SearchByIdCardNumber(query, page, size)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if len(results) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}
	ctx.JSON(http.StatusOK, results)
}

// SearchByLicenseNumber 按驾驶证号搜索
func (c *DriverInformationController) SearchByLicenseNumber(ctx *gin.Context) {
	query := ctx.Query("query")
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(ctx.DefaultQuery("size", "10"))

	results, err := c.driverService.SearchByLicenseNumber(query, page, size)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if len(results) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}
	ctx.JSON(http.StatusOK, results)
}

// SearchByName 按姓名搜索
func (c *DriverInformationController) SearchByName(ctx *gin.Context) {
	query := ctx.Query("query")
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(ctx.DefaultQuery("size", "10"))

	results, err := c.driverService.SearchByName(query, page, size)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if len(results) == 0 {
		ctx.Status(http.StatusNoContent)
		return
	}
	ctx.JSON(http.StatusOK, results)
}

// 更新用户管理修改时间
func (c *DriverInformationController) updateUserModifiedTime(driverId int) {
	user, err := c.userService.GetUserById(driverId)
	if err != nil {
		log.Printf("No UserManagement found for driverId %d", driverId)
		return
	}
	user.ModifiedTime = time.Now()
	c.userService.UpdateUser(user)
}
