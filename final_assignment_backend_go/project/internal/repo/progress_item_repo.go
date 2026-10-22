package repo

import (
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ProgressItemRepo 把前端进度消息映射到共享的 sys_request_history 表，
// 与 Monolith / Quarkus / Cloud 的 /api/progress 使用同一份数据。
type ProgressItemRepo struct {
	db *gorm.DB
}

func NewProgressItemRepo(db *gorm.DB) *ProgressItemRepo {
	return &ProgressItemRepo{db: db}
}

func (r *ProgressItemRepo) FindAll() ([]domain.ProgressItem, error) {
	return r.find(func(query *gorm.DB) *gorm.DB { return query })
}

func (r *ProgressItemRepo) FindByUsername(username string) ([]domain.ProgressItem, error) {
	userID, err := r.lookupUserID(username)
	if err != nil {
		return nil, err
	}
	if userID == 0 {
		return []domain.ProgressItem{}, nil
	}
	return r.find(func(query *gorm.DB) *gorm.DB {
		return query.Where("sys_request_history.user_id = ?", userID)
	})
}

func (r *ProgressItemRepo) FindByStatus(status string) ([]domain.ProgressItem, error) {
	return r.find(func(query *gorm.DB) *gorm.DB {
		return query.Where("sys_request_history.business_status = ?", status)
	})
}

func (r *ProgressItemRepo) FindByTimeRange(start, end time.Time) ([]domain.ProgressItem, error) {
	return r.find(func(query *gorm.DB) *gorm.DB {
		return query.Where("sys_request_history.created_at BETWEEN ? AND ?", start, end)
	})
}

func (r *ProgressItemRepo) FindByIdempotencyKey(key string) (*domain.ProgressItem, error) {
	key = strings.TrimSpace(key)
	if key == "" {
		return nil, nil
	}
	var row progressRow
	// 进度条目的软删除不能抹掉幂等标记：重放请求仍需看到被删除行并得到 208。
	err := r.progressQuery().Unscoped().Where("sys_request_history.idempotency_key = ?", key).Scan(&row).Error
	if err != nil {
		return nil, err
	}
	if row.ID == 0 {
		return nil, nil
	}
	item := progressFromRow(row)
	return &item, nil
}

func (r *ProgressItemRepo) FindByID(id int) (*domain.ProgressItem, error) {
	var row progressRow
	err := r.progressQuery().Where("sys_request_history.id = ?", id).Scan(&row).Error
	if err != nil {
		return nil, err
	}
	if row.ID == 0 {
		return nil, gorm.ErrRecordNotFound
	}
	item := progressFromRow(row)
	return &item, nil
}

func (r *ProgressItemRepo) Create(item *domain.ProgressItem) error {
	return r.CreateWithKey(item, "")
}

func (r *ProgressItemRepo) CreateWithKey(item *domain.ProgressItem, idempotencyKey string) error {
	now := time.Now().Truncate(time.Second)
	submit := item.SubmitTime.Truncate(time.Second)
	if submit.IsZero() {
		submit = now
	}
	key := strings.TrimSpace(idempotencyKey)
	if key == "" {
		key = uuid.NewString()
	}
	row := domain.SysRequestHistory{
		IdempotencyKey: key,
		RequestMethod:  "POST",
		RequestURL:     "/api/progress",
		RequestParams:  item.Details,
		BusinessType:   defaultString(item.Title, "GENERAL"),
		BusinessStatus: item.Status,
		CreatedAt:      submit,
		UpdatedAt:      now,
	}
	if strings.TrimSpace(item.Username) != "" {
		userID, err := r.lookupUserID(item.Username)
		if err != nil {
			return err
		}
		if userID > 0 {
			row.UserID = &userID
		}
	}
	if err := r.db.Create(&row).Error; err != nil {
		return err
	}
	item.ID = int(row.ID)
	item.SubmitTime = submit
	item.UserID = row.UserID
	return nil
}

func (r *ProgressItemRepo) Update(item *domain.ProgressItem) (*domain.ProgressItem, error) {
	var row domain.SysRequestHistory
	if err := r.db.First(&row, item.ID).Error; err != nil {
		return nil, err
	}
	if item.Title != "" {
		row.BusinessType = item.Title
	}
	if item.Status != "" {
		row.BusinessStatus = item.Status
	}
	if item.Details != "" {
		row.RequestParams = item.Details
	}
	// createdAt 与幂等键描述的是创建事实，更新改写它们会让创建请求的重放检测失效。
	if strings.TrimSpace(item.Username) != "" {
		userID, err := r.lookupUserID(item.Username)
		if err != nil {
			return nil, err
		}
		if userID > 0 {
			row.UserID = &userID
		}
	}
	row.UpdatedAt = time.Now().Truncate(time.Second)
	if err := r.db.Save(&row).Error; err != nil {
		return nil, err
	}
	return r.FindByID(int(row.ID))
}

// Delete 只做软删除：共享台账同时承载审计与幂等事实，物理删除会销毁证据。
func (r *ProgressItemRepo) Delete(id int) error {
	return r.db.Delete(&domain.SysRequestHistory{}, id).Error
}

func (r *ProgressItemRepo) find(scope func(*gorm.DB) *gorm.DB) ([]domain.ProgressItem, error) {
	var rows []progressRow
	if err := scope(r.progressQuery()).Order("sys_request_history.updated_at DESC").Scan(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]domain.ProgressItem, 0, len(rows))
	for _, row := range rows {
		items = append(items, progressFromRow(row))
	}
	return items, nil
}

type progressRow struct {
	domain.SysRequestHistory
	Username string `gorm:"column:username"`
}

func (r *ProgressItemRepo) progressQuery() *gorm.DB {
	return r.db.Model(&domain.SysRequestHistory{}).
		Select("sys_request_history.*, u.username AS username").
		Joins("LEFT JOIN sys_user u ON u.user_id = sys_request_history.user_id")
}

func (r *ProgressItemRepo) lookupUserID(username string) (int64, error) {
	username = strings.TrimSpace(username)
	if username == "" {
		return 0, nil
	}
	var userID int64
	err := r.db.Table("sys_user").Select("user_id").Where("username = ?", username).Limit(1).Scan(&userID).Error
	return userID, err
}

func progressFromRow(row progressRow) domain.ProgressItem {
	return domain.ProgressItem{
		ID:         int(row.ID),
		Title:      row.BusinessType,
		Status:     row.BusinessStatus,
		SubmitTime: row.CreatedAt,
		Details:    row.RequestParams,
		Username:   row.Username,
		UserID:     row.UserID,
	}
}

func defaultString(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}
