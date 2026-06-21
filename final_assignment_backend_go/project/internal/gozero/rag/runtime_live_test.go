package rag

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/gozero/config"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/elasticsearch"
	"github.com/testcontainers/testcontainers-go/wait"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func TestRuntimeLiveElasticsearchMySQL(t *testing.T) {
	if os.Getenv("RAG_LIVE_TESTS") != "1" {
		t.Skip("set RAG_LIVE_TESTS=1 to run live MySQL/Elasticsearch integration")
	}
	defer skipIfDockerUnavailable(t)

	ctx := context.Background()
	mysqlContainer, dsn := startLiveMySQL(t, ctx)
	defer mysqlContainer.Terminate(ctx)
	elasticsearchContainer, elasticsearchURL := startLiveElasticsearch(t, ctx)
	defer elasticsearchContainer.Terminate(ctx)

	seedLiveSources(t, dsn)
	runtime, err := NewRuntime(config.RagConf{
		Enabled:                true,
		IndexingEnabled:        true,
		EmbeddingEnabled:       true,
		MySQLDSN:               dsn,
		ElasticsearchAddresses: []string{elasticsearchURL},
		ElasticsearchIndex:     "rag_chunk_live_v1",
		ElasticsearchAlias:     "rag_chunk_live_current",
		EmbeddingProvider:      "deterministic",
		EmbeddingModel:         "deterministic-16",
		EmbeddingDimensions:    16,
		MaxBatchSize:           10,
		MaxRequeueLimit:        10,
		MaxUploadBytes:         defaultUploadBytes,
		AutoMigrate:            true,
	})
	if err != nil {
		t.Fatalf("NewRuntime() error = %v", err)
	}
	defer runtime.Close()

	backfill, err := runtime.Backfill.RunBatch(ctx, 1, 10)
	if err != nil {
		t.Fatalf("RunBatch() error = %v", err)
	}
	if backfill.ProcessedDocuments != 2 || backfill.FailedDocuments != 0 {
		t.Fatalf("unexpected backfill result: %+v", backfill)
	}

	embedding, err := runtime.EmbeddingTasks.ProcessPendingBatch(ctx, 10)
	if err != nil {
		t.Fatalf("ProcessPendingBatch() error = %v", err)
	}
	if embedding.SucceededTasks == 0 || embedding.FailedTasks != 0 {
		t.Fatalf("unexpected embedding result: %+v", embedding)
	}

	migration, err := runtime.Migration.MigrateToNewIndex(ctx, "rag_chunk_live_v2", true, 10)
	if err != nil {
		t.Fatalf("MigrateToNewIndex() error = %v", err)
	}
	if !migration.CreatedIndex || !migration.AliasSwitched {
		t.Fatalf("unexpected migration result: %+v", migration)
	}
}

func skipIfDockerUnavailable(t *testing.T) {
	t.Helper()
	recovered := recover()
	if recovered == nil {
		return
	}
	message := fmt.Sprint(recovered)
	if strings.Contains(strings.ToLower(message), "docker") {
		t.Skipf("Docker is not available for live RAG integration: %v", recovered)
	}
	panic(recovered)
}

func startLiveMySQL(t *testing.T, ctx context.Context) (testcontainers.Container, string) {
	t.Helper()
	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: testcontainers.ContainerRequest{
			Image:        "mysql:8.4",
			ExposedPorts: []string{"3306/tcp"},
			Env: map[string]string{
				"MYSQL_ROOT_PASSWORD": "testpass",
				"MYSQL_DATABASE":      "final_assignment",
			},
			WaitingFor: wait.ForListeningPort("3306/tcp").WithStartupTimeout(2 * time.Minute),
		},
		Started: true,
	})
	if err != nil {
		t.Fatalf("start MySQL container: %v", err)
	}
	host, err := container.Host(ctx)
	if err != nil {
		t.Fatalf("MySQL host: %v", err)
	}
	port, err := container.MappedPort(ctx, "3306/tcp")
	if err != nil {
		t.Fatalf("MySQL port: %v", err)
	}
	dsn := fmt.Sprintf("root:testpass@tcp(%s:%s)/final_assignment?charset=utf8mb4&parseTime=True&loc=UTC", host, port.Port())
	waitForMySQL(t, dsn)
	return container, dsn
}

func startLiveElasticsearch(t *testing.T, ctx context.Context) (*elasticsearch.ElasticsearchContainer, string) {
	t.Helper()
	container, err := elasticsearch.Run(
		ctx,
		"docker.elastic.co/elasticsearch/elasticsearch:8.12.2",
		testcontainers.WithEnv(map[string]string{
			"discovery.type":         "single-node",
			"xpack.security.enabled": "false",
			"ES_JAVA_OPTS":           "-Xms512m -Xmx512m",
		}),
	)
	if err != nil {
		t.Fatalf("start Elasticsearch container: %v", err)
	}
	return container, container.Settings.Address
}

func waitForMySQL(t *testing.T, dsn string) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Minute)
	for {
		db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
		if err == nil {
			sqlDB, err := db.DB()
			if err == nil {
				pingErr := sqlDB.Ping()
				_ = sqlDB.Close()
				if pingErr == nil {
					return
				}
			}
		}
		if time.Now().After(deadline) {
			t.Fatalf("MySQL did not become ready")
		}
		time.Sleep(time.Second)
	}
}

func seedLiveSources(t *testing.T, dsn string) {
	t.Helper()
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		t.Fatalf("open seed DB: %v", err)
	}
	if err := db.AutoMigrate(&domain.OffenseTypeDict{}, &domain.AppealRecord{}); err != nil {
		t.Fatalf("auto-migrate source tables: %v", err)
	}
	now := time.Now().UTC()
	fine := 200.0
	points := 3
	offenseID := int64(1)
	if err := db.Create(&domain.OffenseTypeDict{
		TypeID:             1,
		OffenseCode:        "A001",
		OffenseName:        "Illegal parking",
		Category:           "Parking",
		Description:        "Vehicle stopped in a restricted area.",
		StandardFineAmount: &fine,
		DeductedPoints:     &points,
		SeverityLevel:      "Minor",
		LegalBasis:         "Road Traffic Safety Law Article 93",
		Status:             "Active",
		CreatedAt:          &now,
		UpdatedAt:          &now,
	}).Error; err != nil {
		t.Fatalf("seed offense_type_dict: %v", err)
	}
	if err := db.Create(&domain.AppealRecord{
		AppealID:            1,
		OffenseID:           &offenseID,
		AppealNumber:        "AP-2026-0001",
		AppellantName:       "Alice",
		AppealType:          "Judgment_Error",
		AppealReason:        "Evidence does not match the vehicle.",
		AppealTime:          &now,
		EvidenceDescription: "Camera frame mismatch.",
		AcceptanceStatus:    "Accepted",
		ProcessStatus:       "Under_Review",
		CreatedAt:           &now,
		UpdatedAt:           &now,
	}).Error; err != nil {
		t.Fatalf("seed appeal_record: %v", err)
	}
}
