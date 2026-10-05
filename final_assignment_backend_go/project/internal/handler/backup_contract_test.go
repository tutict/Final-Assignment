package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/domain"

	"github.com/gin-gonic/gin"
)

type backupStub struct {
	rows []domain.BackupRestore
}

func (backupStub) CheckAndInsertIdempotency(string, *domain.BackupRestore, string) error {
	return nil
}
func (backupStub) DeleteBackup(string) error                                  { return nil }
func (s backupStub) GetAllBackups() ([]domain.BackupRestore, error)           { return s.rows, nil }
func (backupStub) GetBackupByFileName(string) (*domain.BackupRestore, error)  { return nil, nil }
func (backupStub) GetBackupById(string) (*domain.BackupRestore, error)        { return nil, nil }
func (backupStub) GetBackupsByTime(time.Time) ([]domain.BackupRestore, error) { return nil, nil }

func TestBackupSearchRoutesMatchFrontend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	when, _ := time.Parse("2006-01-02T15:04:05", "2026-09-30T02:00:00")
	later := when.Add(48 * time.Hour)
	restored := when.Add(3 * time.Hour)
	router := gin.New()
	NewBackupRestoreController(backupStub{rows: []domain.BackupRestore{
		{BackupID: 1, BackupType: "FULL", BackupFileName: "traffic-full.sql", BackupHandler: "admin", Status: "Success", RestoreStatus: "Restored", BackupTime: when, RestoreTime: &restored},
		{BackupID: 2, BackupType: "INCREMENTAL", BackupFileName: "traffic-inc.sql", BackupHandler: "ops", Status: "Failed", RestoreStatus: "Pending", BackupTime: later},
	}}).RegisterRoutes(router)

	assertOne := func(path string, wantID int) {
		t.Helper()
		res := httptest.NewRecorder()
		router.ServeHTTP(res, httptest.NewRequest(http.MethodGet, path, nil))
		if res.Code != http.StatusOK {
			t.Fatalf("%s status=%d body=%s", path, res.Code, res.Body.String())
		}
		var body []domain.BackupRestore
		if err := json.Unmarshal(res.Body.Bytes(), &body); err != nil {
			t.Fatalf("%s %v body=%s", path, err, res.Body.String())
		}
		if len(body) != 1 || body[0].BackupID != wantID {
			t.Fatalf("%s got %#v", path, body)
		}
	}

	assertOne("/api/system/backup/search/type?backupType=FULL", 1)
	assertOne("/api/system/backup/search/file-name?backupFileName=inc", 2)
	assertOne("/api/system/backup/search/handler?backupHandler=ops", 2)
	assertOne("/api/system/backup/search/restore-status?restoreStatus=Restored", 1)
	assertOne("/api/system/backup/search/status?status=Failed", 2)
	assertOne("/api/system/backup/search/backup-time-range?startTime=2026-09-30&endTime=2026-09-30", 1)
	assertOne("/api/system/backup/search/restore-time-range?startTime=2026-09-30T00:00:00&endTime=2026-09-30T23:59:59", 1)
}
