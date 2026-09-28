package reliability

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"gorm.io/gorm"
)

var (
	ErrKeyRequired = errors.New("Idempotency-Key must not be blank")
	ErrReplay      = errors.New("duplicate ledger request")
	ErrConflict    = errors.New("Idempotency-Key was reused with a different payload")
	ErrInProgress  = errors.New("Idempotency-Key is already in progress")
)

type RequestHistory struct {
	ID             int64     `gorm:"column:id;primaryKey"`
	IdempotencyKey string    `gorm:"column:idempotency_key"`
	RequestMethod  string    `gorm:"column:request_method"`
	RequestURL     string    `gorm:"column:request_url"`
	RequestParams  string    `gorm:"column:request_params"`
	BusinessType   string    `gorm:"column:business_type"`
	BusinessID     *int64    `gorm:"column:business_id"`
	BusinessStatus string    `gorm:"column:business_status"`
	CreatedAt      time.Time `gorm:"column:created_at"`
	UpdatedAt      time.Time `gorm:"column:updated_at"`
}

func (RequestHistory) TableName() string { return "sys_request_history" }

func Fingerprint(canonical string) string {
	sum := sha256.Sum256([]byte(canonical))
	return "sha256:" + hex.EncodeToString(sum[:])
}

func Reserve(db *gorm.DB, key, businessType, method, url, fingerprint string, businessID *int64) error {
	db = Ledger(db)
	key = strings.TrimSpace(key)
	if key == "" {
		return ErrKeyRequired
	}
	var existing RequestHistory
	err := db.Where("idempotency_key = ?", key).First(&existing).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		row := RequestHistory{
			IdempotencyKey: key,
			RequestMethod:  method,
			RequestURL:     url,
			RequestParams:  fingerprint,
			BusinessType:   businessType,
			BusinessID:     businessID,
			BusinessStatus: "PROCESSING",
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		}
		if createErr := db.Create(&row).Error; createErr != nil {
			if reread := db.Where("idempotency_key = ?", key).First(&existing).Error; reread != nil {
				return createErr
			}
			return applyExisting(db, &existing, fingerprint, method, url, businessType, businessID)
		}
		return nil
	}
	if err != nil {
		return err
	}
	return applyExisting(db, &existing, fingerprint, method, url, businessType, businessID)
}

func MarkSuccess(db *gorm.DB, key string, businessID int64) error {
	db = Ledger(db)
	var row RequestHistory
	if err := db.Where("idempotency_key = ?", key).First(&row).Error; err != nil {
		return err
	}
	row.BusinessStatus = "SUCCESS"
	row.BusinessID = &businessID
	if !strings.HasPrefix(row.RequestParams, "sha256:") {
		row.RequestParams = "DONE"
	}
	row.UpdatedAt = time.Now()
	return db.Save(&row).Error
}

func Finish(db *gorm.DB, key string, businessID int64, writeErr error) error {
	if writeErr != nil {
		_ = MarkFailed(db, key, writeErr.Error())
		return writeErr
	}
	if businessID > 0 {
		return MarkSuccess(db, key, businessID)
	}
	return nil
}
func MarkFailed(db *gorm.DB, key, reason string) error {
	db = Ledger(db)
	var row RequestHistory
	if err := db.Where("idempotency_key = ?", strings.TrimSpace(key)).First(&row).Error; err != nil {
		return err
	}
	row.BusinessStatus = "FAILED"
	if len(reason) > 500 {
		reason = reason[:500]
	}
	row.RequestParams = reason
	row.UpdatedAt = time.Now()
	return db.Save(&row).Error
}

func applyExisting(db *gorm.DB, existing *RequestHistory, fingerprint, method, url, businessType string, businessID *int64) error {
	stamp := existing.UpdatedAt
	if stamp.IsZero() {
		stamp = existing.CreatedAt
	}
	outcome := Decide(true, existing.BusinessStatus, existing.RequestParams, fingerprint, time.Since(stamp))
	switch outcome {
	case Replay:
		return ErrReplay
	case Conflict:
		return ErrConflict
	case InProgress:
		return ErrInProgress
	default:
		existing.RequestMethod = method
		existing.RequestURL = url
		existing.RequestParams = fingerprint
		existing.BusinessType = businessType
		existing.BusinessID = businessID
		existing.BusinessStatus = "PROCESSING"
		existing.UpdatedAt = time.Now()
		return db.Save(existing).Error
	}
}

func ReconcileStale(db *gorm.DB, now time.Time) (int, error) {
	cutoff := now.Add(-ProcessingTTL)
	var rows []RequestHistory
	if err := db.Where("business_status = ? AND updated_at < ?", "PROCESSING", cutoff).Find(&rows).Error; err != nil {
		return 0, err
	}
	changed := 0
	for _, row := range rows {
		exists := false
		if row.BusinessID != nil {
			exists = ledgerRowExists(db, row.BusinessType, *row.BusinessID)
		}
		next := "FAILED"
		if exists {
			next = "SUCCESS"
		}
		result := db.Model(&RequestHistory{}).
			Where("id = ? AND business_status = ?", row.ID, "PROCESSING").
			Updates(map[string]any{"business_status": next, "updated_at": now})
		if result.Error != nil {
			return changed, result.Error
		}
		changed += int(result.RowsAffected)
	}
	return changed, nil
}

func ledgerRowExists(db *gorm.DB, businessType string, businessID int64) bool {
	table, column := ledgerTable(businessType)
	if table == "" {
		return false
	}
	var count int64
	err := db.Table(table).Where(column+" = ?", businessID).Count(&count).Error
	return err == nil && count > 0
}

func ledgerTable(businessType string) (string, string) {
	value := strings.ToUpper(businessType)
	switch {
	case strings.HasPrefix(value, "PAYMENT"):
		return "payment_record", "payment_id"
	case strings.HasPrefix(value, "FINE"):
		return "fine_record", "fine_id"
	case strings.HasPrefix(value, "DEDUCTION"):
		return "deduction_record", "deduction_id"
	case strings.HasPrefix(value, "APPEAL_REVIEW"):
		return "appeal_review", "review_id"
	case strings.HasPrefix(value, "APPEAL"):
		return "appeal_record", "appeal_id"
	default:
		return "", ""
	}
}
