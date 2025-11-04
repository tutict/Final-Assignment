package handler

import (
	"log"
	"net/http"
	"net/url"
	"strconv"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

type VehicleController struct {
	vehicleService *service.VehicleService
}

func NewVehicleController(vehicleService *service.VehicleService) *VehicleController {
	return &VehicleController{vehicleService: vehicleService}
}

// 注册路由
func (vc *VehicleController) RegisterRoutes(r *gin.Engine) {
	v := r.Group("/api/vehicles")
	{
		v.GET("/search", vc.SearchVehicles)
		v.GET("/autocomplete/license-plate/me", vc.GetLicensePlateAutocomplete)
		v.GET("/autocomplete/vehicle-type/me", vc.GetVehicleTypeAutocomplete)
		v.GET("/autocomplete/license-plate-globally/me", vc.GetLicensePlateAutocompleteGlobally)
		v.GET("/autocomplete/vehicle-type-globally/me", vc.GetVehicleTypeAutocompleteGlobally)
		v.POST("", vc.CreateVehicle)
		v.GET("/:vehicleId", vc.GetVehicleById)
		v.GET("/license-plate/:licensePlate", vc.GetVehicleByLicensePlate)
		v.GET("", vc.GetAllVehicles)
		v.GET("/type/:vehicleType", vc.GetByType)
		v.GET("/owner/:ownerName", vc.GetByOwnerName)
		v.GET("/id-card-number/:idCardNumber", vc.GetByIdCardNumber)
		v.GET("/status/:status", vc.GetByStatus)
		v.PUT("/:vehicleId", vc.UpdateVehicle)
		v.DELETE("/:vehicleId", vc.DeleteById)
		v.DELETE("/license-plate/:licensePlate", vc.DeleteByLicensePlate)
		v.GET("/exists/:licensePlate", vc.IsLicensePlateExists)
	}
}

// --- Handler 实现 ---

func (vc *VehicleController) SearchVehicles(c *gin.Context) {
	query := c.Query("query")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "10"))

	vehicles, err := vc.vehicleService.SearchVehicles(query, page, size)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vehicles)
}

func (vc *VehicleController) GetLicensePlateAutocomplete(c *gin.Context) {
	prefix := c.Query("prefix")
	idCard := c.Query("idCardNumber")
	maxSuggestions, _ := strconv.Atoi(c.DefaultQuery("maxSuggestions", "5"))

	prefix, _ = url.QueryUnescape(prefix)
	idCard, _ = url.QueryUnescape(idCard)

	suggestions := vc.vehicleService.GetLicensePlateAutocomplete(idCard, prefix, maxSuggestions)
	c.JSON(http.StatusOK, suggestions)
}

func (vc *VehicleController) GetVehicleTypeAutocomplete(c *gin.Context) {
	prefix := c.Query("prefix")
	idCard := c.Query("idCardNumber")
	maxSuggestions, _ := strconv.Atoi(c.DefaultQuery("maxSuggestions", "5"))

	prefix, _ = url.QueryUnescape(prefix)
	idCard, _ = url.QueryUnescape(idCard)

	suggestions := vc.vehicleService.GetVehicleTypeAutocomplete(idCard, prefix, maxSuggestions)
	c.JSON(http.StatusOK, suggestions)
}

func (vc *VehicleController) GetLicensePlateAutocompleteGlobally(c *gin.Context) {
	prefix := c.Query("licensePlate")
	prefix, _ = url.QueryUnescape(prefix)

	suggestions := vc.vehicleService.GetLicensePlateGlobally(prefix)
	c.JSON(http.StatusOK, suggestions)
}

func (vc *VehicleController) GetVehicleTypeAutocompleteGlobally(c *gin.Context) {
	prefix := c.Query("vehicleType")
	prefix, _ = url.QueryUnescape(prefix)

	suggestions := vc.vehicleService.GetVehicleTypeGlobally(prefix)
	c.JSON(http.StatusOK, suggestions)
}

func (vc *VehicleController) CreateVehicle(c *gin.Context) {
	var vehicle domain.VehicleInformation
	idempotencyKey := c.Query("idempotencyKey")

	if err := c.ShouldBindJSON(&vehicle); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := vc.vehicleService.CreateVehicle(idempotencyKey, &vehicle); err != nil {
		if err.Error() == "Duplicate request" {
			c.Status(http.StatusConflict)
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		}
		return
	}
	c.Status(http.StatusCreated)
}

func (vc *VehicleController) GetVehicleById(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("vehicleId"))
	vehicle, err := vc.vehicleService.GetById(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vehicle)
}

func (vc *VehicleController) GetVehicleByLicensePlate(c *gin.Context) {
	lp := c.Param("licensePlate")
	vehicle, err := vc.vehicleService.GetByLicensePlate(lp)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vehicle)
}

func (vc *VehicleController) GetAllVehicles(c *gin.Context) {
	list := vc.vehicleService.GetAll()
	c.JSON(http.StatusOK, list)
}

func (vc *VehicleController) GetByType(c *gin.Context) {
	typ := c.Param("vehicleType")
	list := vc.vehicleService.GetByType(typ)
	c.JSON(http.StatusOK, list)
}

func (vc *VehicleController) GetByOwnerName(c *gin.Context) {
	name := c.Param("ownerName")
	list := vc.vehicleService.GetByOwnerName(name)
	c.JSON(http.StatusOK, list)
}

func (vc *VehicleController) GetByIdCardNumber(c *gin.Context) {
	idCard := c.Param("idCardNumber")
	list := vc.vehicleService.GetByIdCardNumber(idCard)
	c.JSON(http.StatusOK, list)
}

func (vc *VehicleController) GetByStatus(c *gin.Context) {
	status := c.Param("status")
	list := vc.vehicleService.GetByStatus(status)
	c.JSON(http.StatusOK, list)
}

func (vc *VehicleController) UpdateVehicle(c *gin.Context) {
	var vehicle domain.VehicleInformation
	idempotencyKey := c.Query("idempotencyKey")
	id, _ := strconv.Atoi(c.Param("vehicleId"))

	if err := c.ShouldBindJSON(&vehicle); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	vehicle.VehicleID = id
	if err := vc.vehicleService.UpdateVehicle(idempotencyKey, &vehicle); err != nil {
		if err.Error() == "Duplicate request" {
			c.Status(http.StatusConflict)
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		}
		return
	}
	c.JSON(http.StatusOK, vehicle)
}

func (vc *VehicleController) DeleteById(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("vehicleId"))
	if err := vc.vehicleService.DeleteById(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

func (vc *VehicleController) DeleteByLicensePlate(c *gin.Context) {
	lp := c.Param("licensePlate")
	if err := vc.vehicleService.DeleteByLicensePlate(lp); err != nil {
		log.Println("Failed to delete:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

func (vc *VehicleController) IsLicensePlateExists(c *gin.Context) {
	lp := c.Param("licensePlate")
	exists := vc.vehicleService.IsLicensePlateExists(lp)
	c.JSON(http.StatusOK, gin.H{"exists": exists})
}
