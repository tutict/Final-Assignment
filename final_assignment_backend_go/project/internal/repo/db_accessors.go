package repo

import "gorm.io/gorm"

func (r *AppealManagementRepo) DB() *gorm.DB     { return r.db }
func (r *BackupRestoreRepo) DB() *gorm.DB        { return r.db }
func (r *DeductionInformationRepo) DB() *gorm.DB { return r.db }
func (r *DriverInformationRepo) DB() *gorm.DB    { return r.db }
func (r *FineInformationRepo) DB() *gorm.DB      { return r.db }
func (r *LoginLogRepo) DB() *gorm.DB             { return r.db }
func (r *OffenseDetailsRepo) DB() *gorm.DB       { return r.db }
func (r *OffenseInformationRepo) DB() *gorm.DB   { return r.db }
func (r *OperationLogRepo) DB() *gorm.DB         { return r.db }
func (r *PermissionManagementRepo) DB() *gorm.DB { return r.db }
func (r *ProgressItemRepo) DB() *gorm.DB         { return r.db }
func (r *RequestHistoryRepo) DB() *gorm.DB       { return r.db }
func (r *RoleManagementRepo) DB() *gorm.DB       { return r.db }
func (r *SystemLogsRepo) DB() *gorm.DB           { return r.db }
func (r *SystemSettingsRepo) DB() *gorm.DB       { return r.db }
func (r *UserManagementRepo) DB() *gorm.DB       { return r.db }
func (r *UserRoleRepo) DB() *gorm.DB             { return r.db }
func (r *VehicleInformationRepo) DB() *gorm.DB   { return r.db }
