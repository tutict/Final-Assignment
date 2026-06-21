package handler

import (
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service"
)

type AppealService interface {
	CheckAndInsertIdempotency(string, *domain.AppealManagement, string) (*domain.AppealManagement, error)
	CountAppealsByStatus(string) (int64, error)
	DeleteAppeal(uint) error
	GetAllAppeals() ([]domain.AppealManagement, error)
	GetAppealByID(uint) (*domain.AppealManagement, error)
	GetAppealsByAppellantName(string) ([]domain.AppealManagement, error)
	GetAppealsByContactNumber(string) ([]domain.AppealManagement, error)
	GetAppealsByIdCardNumber(string) ([]domain.AppealManagement, error)
	GetAppealsByOffenseID(uint) ([]domain.AppealManagement, error)
	GetAppealsByProcessStatus(string) ([]domain.AppealManagement, error)
	GetAppealsByTimeRange(time.Time, time.Time) ([]domain.AppealManagement, error)
	GetOffenseByAppealID(uint) (*domain.OffenseInformation, error)
}

type AuthService interface {
	GetAllUsers() ([]domain.UserManagement, error)
	Login(service.LoginRequest) (map[string]any, error)
	RegisterUser(service.RegisterRequest) (string, error)
}

type BackupRestoreService interface {
	CheckAndInsertIdempotency(string, *domain.BackupRestore, string) error
	DeleteBackup(string) error
	GetAllBackups() ([]domain.BackupRestore, error)
	GetBackupByFileName(string) (*domain.BackupRestore, error)
	GetBackupById(string) (*domain.BackupRestore, error)
	GetBackupsByTime(time.Time) ([]domain.BackupRestore, error)
}

type DeductionInformationService interface {
	CheckAndInsertIdempotency(string, *domain.DeductionInformation, string) error
	DeleteDeduction(string) error
	GetAllDeductions() ([]domain.DeductionInformation, error)
	GetDeductionById(string) (*domain.DeductionInformation, error)
	GetDeductionsByHandler(string) ([]domain.DeductionInformation, error)
	GetDeductionsByTimeRange(time.Time, time.Time) ([]domain.DeductionInformation, error)
	SearchByDeductionTimeRange(time.Time, time.Time, int) ([]domain.DeductionInformation, error)
	SearchByHandler(string, int) ([]domain.DeductionInformation, error)
}

type DriverInformationService interface {
	CheckAndInsertIdempotency(string, *domain.DriverInformation, string) error
	DeleteDriver(int) error
	GetAllDrivers() ([]domain.DriverInformation, error)
	GetDriverById(int) (*domain.DriverInformation, error)
	SearchByIdCardNumber(string, int, int) ([]domain.DriverInformation, error)
	SearchByLicenseNumber(string, int, int) ([]domain.DriverInformation, error)
	SearchByName(string, int, int) ([]domain.DriverInformation, error)
}

type FineInformationService interface {
	CheckAndInsertIdempotency(string, *domain.FineInformation, string) error
	DeleteFine(string) error
	GetAllFines() ([]domain.FineInformation, error)
	GetFineByID(string) (*domain.FineInformation, error)
	GetFineByReceiptNumber(string) (*domain.FineInformation, error)
	GetFinesByPayee(string) ([]domain.FineInformation, error)
	GetFinesByTimeRange(time.Time, time.Time) ([]domain.FineInformation, error)
	SearchByFineTimeRange(time.Time, time.Time, string) ([]domain.FineInformation, error)
}

type LoginLogService interface {
	CheckAndInsertIdempotency(string, *domain.LoginLog, string) error
	DeleteLoginLog(string) error
	GetAllLoginLogs() ([]domain.LoginLog, error)
	GetLoginLogByID(string) (*domain.LoginLog, error)
	GetLoginLogsByLoginResult(string) ([]domain.LoginLog, error)
	GetLoginLogsByTimeRange(time.Time, time.Time) ([]domain.LoginLog, error)
	GetLoginLogsByUsername(string) ([]domain.LoginLog, error)
	GetLoginResultsByPrefixGlobally(string) []string
	GetUsernamesByPrefixGlobally(string) []string
}

type OffenseInformationService interface {
	CheckAndInsertIdempotency(string, *domain.OffenseInformation, string) error
	DeleteOffense(int) error
	GetAllOffenses() ([]domain.OffenseInformation, error)
	GetOffenseByID(int) (*domain.OffenseInformation, error)
	GetOffensesByTimeRange(time.Time, time.Time) ([]domain.OffenseInformation, error)
	SearchByDriverName(string, int, int) ([]domain.OffenseInformation, error)
	SearchByLicensePlate(string, int, int) ([]domain.OffenseInformation, error)
	SearchByOffenseType(string, int, int) ([]domain.OffenseInformation, error)
}

type OperationLogService interface {
	CheckAndInsertIdempotency(string, *domain.OperationLog, string) error
	DeleteOperationLog(int) error
	GetAllOperationLogs() ([]domain.OperationLog, error)
	GetOperationLog(int) (*domain.OperationLog, error)
	GetOperationLogsByResult(string) ([]domain.OperationLog, error)
	GetOperationLogsByTimeRange(time.Time, time.Time) ([]domain.OperationLog, error)
	GetOperationLogsByUserId(string) ([]domain.OperationLog, error)
	GetOperationResultsByPrefixGlobally(string) ([]string, error)
	GetUserIdsByPrefixGlobally(string) ([]string, error)
}

type PermissionService interface {
	CheckAndInsertIdempotency(string, *domain.PermissionManagement, string) error
	DeletePermission(int) error
	DeletePermissionByName(string) error
	GetAllPermissions() ([]domain.PermissionManagement, error)
	GetPermissionById(int) (*domain.PermissionManagement, error)
	GetPermissionByName(string) (*domain.PermissionManagement, error)
	GetPermissionsByNameLike(string) ([]domain.PermissionManagement, error)
	UpdatePermission(int, string, *domain.PermissionManagement) error
}

type ProgressService interface {
	CreateProgress(*domain.ProgressItem) (*domain.ProgressItem, error)
	DeleteProgress(int) error
	GetAllProgress() ([]domain.ProgressItem, error)
	GetProgressByStatus(string) ([]domain.ProgressItem, error)
	GetProgressByTimeRange(time.Time, time.Time) ([]domain.ProgressItem, error)
	GetProgressByUsername(string) ([]domain.ProgressItem, error)
	UpdateProgressStatus(int, string) (*domain.ProgressItem, error)
}

type RoleManagementService interface {
	CheckAndInsertIdempotency(string, *domain.RoleManagement, string) error
	DeleteRole(string) error
	DeleteRoleByName(string) error
	GetAllRoles() ([]domain.RoleManagement, error)
	GetRoleById(string) (*domain.RoleManagement, error)
	GetRoleByName(string) (*domain.RoleManagement, error)
	GetRolesByNameLike(string) ([]domain.RoleManagement, error)
}

type SystemLogsService interface {
	CheckAndInsertIdempotency(string, *domain.SystemLogs, string) error
	DeleteSystemLog(string) error
	GetAllSystemLogs() ([]domain.SystemLogs, error)
	GetLogTypesByPrefixGlobally(string) ([]string, error)
	GetOperationUsersByPrefixGlobally(string) ([]string, error)
	GetSystemLogByID(string) (*domain.SystemLogs, error)
	GetSystemLogsByOperationUser(string) ([]domain.SystemLogs, error)
	GetSystemLogsByTimeRange(time.Time, time.Time) ([]domain.SystemLogs, error)
	GetSystemLogsByType(string) ([]domain.SystemLogs, error)
}

type SystemSettingsService interface {
	CheckAndInsertIdempotency(string, *domain.SystemSettings) error
	GetCopyrightInfo() string
	GetDateFormat() string
	GetEmailAccount() string
	GetEmailPassword() string
	GetLoginTimeout() int
	GetPageSize() int
	GetSessionTimeout() int
	GetSmtpServer() string
	GetStoragePath() string
	GetSystemDescription() string
	GetSystemName() string
	GetSystemSettings() (*domain.SystemSettings, error)
	GetSystemVersion() string
}

type TrafficViolationService interface {
	GetAppealReasonCounts(string, string) (any, error)
	GetFinePaymentStatus(string) (any, error)
	GetTimeSeriesData(string, string) (any, error)
	GetViolationTypeCounts(string, string, string) (any, error)
}

type UserManagementService interface {
	CheckAndInsertIdempotency(string, *domain.UserManagement, string) error
	DeleteUserByID(string) error
	DeleteUserByUsername(string) error
	GetAllUsers() ([]domain.UserManagement, error)
	GetPhoneNumbersByPrefixGlobally(string) ([]string, error)
	GetStatusesByPrefixGlobally(string) ([]string, error)
	GetUserByID(string) (*domain.UserManagement, error)
	GetUserById(int) (*domain.UserManagement, error)
	GetUserByUsername(string) (*domain.UserManagement, error)
	GetUsernamesByPrefixGlobally(string) ([]string, error)
	GetUsersByRole(string) ([]domain.UserManagement, error)
	GetUsersByStatus(string) ([]domain.UserManagement, error)
	IsUsernameExists(string) bool
	UpdateUser(*domain.UserManagement) error
	UpdateUserByID(string, *domain.UserManagement, string) error
}

type VehicleService interface {
	CreateVehicle(string, *domain.VehicleInformation) error
	DeleteById(int) error
	DeleteByLicensePlate(string) error
	GetAll() []domain.VehicleInformation
	GetById(int) (*domain.VehicleInformation, error)
	GetByIdCardNumber(string) []domain.VehicleInformation
	GetByLicensePlate(string) (*domain.VehicleInformation, error)
	GetByOwnerName(string) []domain.VehicleInformation
	GetByStatus(string) []domain.VehicleInformation
	GetByType(string) []domain.VehicleInformation
	GetLicensePlateAutocomplete(string, string, int) []string
	GetLicensePlateGlobally(string) []string
	GetVehicleTypeAutocomplete(string, string, int) []string
	GetVehicleTypeGlobally(string) []string
	IsLicensePlateExists(string) bool
	SearchVehicles(string, int, int) ([]domain.VehicleInformation, error)
	UpdateVehicle(string, *domain.VehicleInformation) error
}
