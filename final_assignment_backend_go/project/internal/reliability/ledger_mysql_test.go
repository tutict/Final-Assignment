package reliability

import (
	"fmt"
	"sync"
	"testing"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func openTraffic(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(mysql.Open("root:root@tcp(127.0.0.1:3306)/traffic?parseTime=true&charset=utf8mb4&loc=Local"), &gorm.Config{})
	if err != nil {
		t.Skip(err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		t.Skip(err)
	}
	if err = sqlDB.Ping(); err != nil {
		t.Skip(err)
	}
	return db
}

func TestReserveReplayConflictAndFailedRetry(t *testing.T) {
	db := openTraffic(t)
	key := fmt.Sprintf("reliability-test-%d", time.Now().UnixNano())
	t.Cleanup(func() {
		db.Where("idempotency_key = ?", key).Delete(&RequestHistory{})
	})
	fp := Fingerprint("fine|1|amount|10")
	if err := Reserve(db, key, "PAYMENT_CREATE", "POST", "/api/payments", fp, nil); err != nil {
		t.Fatal(err)
	}
	if err := Reserve(db, key, "PAYMENT_CREATE", "POST", "/api/payments", fp, nil); err != ErrInProgress && err != ErrReplay {
		t.Fatalf("second reserve = %v", err)
	}
	if err := MarkSuccess(db, key, 4); err != nil {
		t.Fatal(err)
	}
	if err := Reserve(db, key, "PAYMENT_CREATE", "POST", "/api/payments", fp, nil); err != ErrReplay {
		t.Fatalf("replay = %v", err)
	}
	if err := Reserve(db, key, "PAYMENT_CREATE", "POST", "/api/payments", Fingerprint("other"), nil); err != ErrConflict {
		t.Fatalf("conflict = %v", err)
	}
	if err := db.Model(&RequestHistory{}).Where("idempotency_key = ?", key).Update("business_status", "FAILED").Error; err != nil {
		t.Fatal(err)
	}
	if err := Reserve(db, key, "PAYMENT_CREATE", "POST", "/api/payments", fp, nil); err != nil {
		t.Fatalf("retry = %v", err)
	}
	var row RequestHistory
	if err := db.Where("idempotency_key = ?", key).First(&row).Error; err != nil {
		t.Fatal(err)
	}
	if row.BusinessStatus != "PROCESSING" {
		t.Fatalf("status after retry = %s", row.BusinessStatus)
	}
}

func TestConcurrentReserveSingleWinner(t *testing.T) {
	db := openTraffic(t)
	key := fmt.Sprintf("reliability-concurrent-%d", time.Now().UnixNano())
	t.Cleanup(func() {
		db.Where("idempotency_key = ?", key).Delete(&RequestHistory{})
	})
	fp := Fingerprint("same")
	var wg sync.WaitGroup
	errs := make([]error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			errs[i] = Reserve(db, key, "PAYMENT_CREATE", "POST", "/api/payments", fp, nil)
		}(i)
	}
	wg.Wait()
	wins := 0
	for _, err := range errs {
		if err == nil {
			wins++
		}
	}
	if wins != 1 {
		t.Fatalf("wins = %d errs=%v", wins, errs)
	}
}

func TestReconcileStaleProcessing(t *testing.T) {
	db := openTraffic(t)
	missingKey := fmt.Sprintf("reliability-missing-%d", time.Now().UnixNano())
	foundKey := fmt.Sprintf("reliability-found-%d", time.Now().UnixNano())
	t.Cleanup(func() {
		db.Where("idempotency_key in ?", []string{missingKey, foundKey}).Delete(&RequestHistory{})
	})
	past := time.Now().Add(-5 * time.Minute)
	paymentID := int64(4)
	rows := []RequestHistory{
		{IdempotencyKey: missingKey, RequestMethod: "POST", RequestURL: "/api/payments", RequestParams: "sha256:missing", BusinessType: "PAYMENT_CREATE", BusinessStatus: "PROCESSING", CreatedAt: past, UpdatedAt: past},
		{IdempotencyKey: foundKey, RequestMethod: "POST", RequestURL: "/api/payments", RequestParams: "sha256:found", BusinessType: "PAYMENT_CREATE", BusinessID: &paymentID, BusinessStatus: "PROCESSING", CreatedAt: past, UpdatedAt: past},
	}
	if err := db.Create(&rows).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Exec("UPDATE sys_request_history SET created_at = ?, updated_at = ? WHERE idempotency_key IN ?", past, past, []string{missingKey, foundKey}).Error; err != nil {
		t.Fatal(err)
	}
	if _, err := ReconcileStale(db, time.Now()); err != nil {
		t.Fatal(err)
	}
	var missing, found RequestHistory
	if err := db.Where("idempotency_key = ?", missingKey).First(&missing).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Where("idempotency_key = ?", foundKey).First(&found).Error; err != nil {
		t.Fatal(err)
	}
	if missing.BusinessStatus != "FAILED" || found.BusinessStatus != "SUCCESS" {
		t.Fatalf("missing=%s found=%s", missing.BusinessStatus, found.BusinessStatus)
	}
}
