package service

import (
	"errors"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/repo"

	"gorm.io/gorm"
)

// OffenseTypeDictService 提供违法类型字典的业务逻辑，对齐 Spring 的
// com.tutict.finalassignmentbackend.service.offense.OffenseTypeDictService。
type OffenseTypeDictService struct {
	repo *repo.OffenseTypeDictRepo
}

func NewOffenseTypeDictService(dictRepo *repo.OffenseTypeDictRepo) *OffenseTypeDictService {
	return &OffenseTypeDictService{repo: dictRepo}
}

func (s *OffenseTypeDictService) DB() *gorm.DB { return s.repo.DB() }

// ErrOffenseTypeDuplicate 对齐 Spring 的重复幂等键拒绝（HTTP 208）。
var ErrOffenseTypeDuplicate = errors.New("duplicate offense type request")

// CheckAndInsertIdempotency 幂等检查 + 落库，沿用 Go 后端统一的幂等账本。
func (s *OffenseTypeDictService) CheckAndInsertIdempotency(key string, dict *domain.OffenseTypeDict, operation string) error {
	if err := checkIdempotency(key, "offense_type:"+operation); err != nil {
		return ErrOffenseTypeDuplicate
	}
	if strings.EqualFold(operation, "create") {
		_, err := s.CreateDict(dict)
		return err
	}
	return s.UpdateDict(dict)
}

// CreateDict 创建违法类型，缺省补齐状态与时间戳。
func (s *OffenseTypeDictService) CreateDict(dict *domain.OffenseTypeDict) (*domain.OffenseTypeDict, error) {
	if dict == nil {
		return nil, errors.New("offense type must not be null")
	}
	if strings.TrimSpace(dict.OffenseCode) == "" {
		return nil, errors.New("offenseCode must not be blank")
	}
	if strings.TrimSpace(dict.OffenseName) == "" {
		return nil, errors.New("offenseName must not be blank")
	}
	now := time.Now()
	if dict.CreatedAt == nil {
		dict.CreatedAt = &now
	}
	if dict.UpdatedAt == nil {
		dict.UpdatedAt = &now
	}
	if strings.TrimSpace(dict.Status) == "" {
		dict.Status = "Active"
	}
	if err := s.repo.Create(dict); err != nil {
		return nil, err
	}
	return dict, nil
}

// UpdateDict 更新违法类型。
func (s *OffenseTypeDictService) UpdateDict(dict *domain.OffenseTypeDict) error {
	if dict == nil || dict.TypeID <= 0 {
		return errors.New("type ID must be greater than zero")
	}
	now := time.Now()
	dict.UpdatedAt = &now
	return s.DB().Save(dict).Error
}

// DeleteDict 删除违法类型（软删除）。
func (s *OffenseTypeDictService) DeleteDict(typeID int) error {
	return s.DB().Where("type_id = ?", typeID).Delete(&domain.OffenseTypeDict{}).Error
}

// FindByID 按主键查询违法类型。
func (s *OffenseTypeDictService) FindByID(typeID int) (*domain.OffenseTypeDict, error) {
	var dict domain.OffenseTypeDict
	err := s.DB().Where("type_id = ?", typeID).First(&dict).Error
	if err != nil {
		return nil, err
	}
	return &dict, nil
}

// FindAll 查询全部违法类型。
func (s *OffenseTypeDictService) FindAll() ([]domain.OffenseTypeDict, error) {
	return s.repo.FindAll()
}

// SearchByOffenseCodePrefix 按违法代码前缀搜索。
func (s *OffenseTypeDictService) SearchByOffenseCodePrefix(code string, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("offense_code LIKE ?", prefixLike(code)), page, size)
}

// SearchByOffenseCodeFuzzy 按违法代码模糊搜索。
func (s *OffenseTypeDictService) SearchByOffenseCodeFuzzy(code string, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("offense_code LIKE ?", like(code)), page, size)
}

// SearchByOffenseNamePrefix 按违法名称前缀搜索。
func (s *OffenseTypeDictService) SearchByOffenseNamePrefix(name string, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("offense_name LIKE ?", prefixLike(name)), page, size)
}

// SearchByOffenseNameFuzzy 按违法名称模糊搜索。
func (s *OffenseTypeDictService) SearchByOffenseNameFuzzy(name string, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("offense_name LIKE ?", like(name)), page, size)
}

// SearchByCategory 按违法类别搜索。
func (s *OffenseTypeDictService) SearchByCategory(category string, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("category = ?", strings.TrimSpace(category)), page, size)
}

// SearchBySeverityLevel 按严重程度搜索。
func (s *OffenseTypeDictService) SearchBySeverityLevel(severity string, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("severity_level = ?", strings.TrimSpace(severity)), page, size)
}

// SearchByStatus 按状态搜索。
func (s *OffenseTypeDictService) SearchByStatus(status string, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("status = ?", strings.TrimSpace(status)), page, size)
}

// SearchByStandardFineAmountRange 按标准罚款金额范围搜索。
func (s *OffenseTypeDictService) SearchByStandardFineAmountRange(minAmount float64, maxAmount float64, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("standard_fine_amount BETWEEN ? AND ?", minAmount, maxAmount), page, size)
}

// SearchByDeductedPointsRange 按扣分范围搜索。
func (s *OffenseTypeDictService) SearchByDeductedPointsRange(minPoints int, maxPoints int, page int, size int) ([]domain.OffenseTypeDict, error) {
	return s.dictPage(s.DB().Where("deducted_points BETWEEN ? AND ?", minPoints, maxPoints), page, size)
}

func (s *OffenseTypeDictService) dictPage(query *gorm.DB, page int, size int) ([]domain.OffenseTypeDict, error) {
	offset, limit := pageBounds(page, size)
	var dicts []domain.OffenseTypeDict
	err := query.Order("type_id").Offset(offset).Limit(limit).Find(&dicts).Error
	return dicts, err
}
