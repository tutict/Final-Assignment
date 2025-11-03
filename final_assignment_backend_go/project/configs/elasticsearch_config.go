package config

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/elastic/go-elasticsearch/v8"
)

// =============================
// 初始化 Elasticsearch 客户端
// =============================

type ElasticSearchConfig struct {
	Client *elasticsearch.Client
	// 可选: 数据源（模拟原来的 MyBatis Mapper）
	DB DataSource
}

// NewElasticSearchConfig 创建 ES 客户端
func NewElasticSearchConfig(uri string, db DataSource) (*ElasticSearchConfig, error) {
	cfg := elasticsearch.Config{
		Addresses: []string{uri},
	}

	es, err := elasticsearch.NewClient(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create Elasticsearch client: %v", err)
	}

	return &ElasticSearchConfig{
		Client: es,
		DB:     db,
	}, nil
}

// =============================
// 核心同步逻辑（等价 @PostConstruct）
// =============================

func (e *ElasticSearchConfig) SyncDatabaseToElasticsearch() error {
	log.Println("Starting synchronization of database to Elasticsearch")

	ctx := context.Background()

	syncTasks := []struct {
		Name     string
		Entities interface{}
	}{
		{"vehicles", e.DB.GetVehicles()},
		{"drivers", e.DB.GetDrivers()},
		{"offenses", e.DB.GetOffenses()},
		{"appeals", e.DB.GetAppeals()},
		{"fines", e.DB.GetFines()},
		{"deductions", e.DB.GetDeductions()},
		{"offense_details", e.DB.GetOffenseDetails()},
		{"users", e.DB.GetUsers()},
		{"login_logs", e.DB.GetLoginLogs()},
		{"operation_logs", e.DB.GetOperationLogs()},
		{"system_logs", e.DB.GetSystemLogs()},
	}

	for _, task := range syncTasks {
		if task.Entities == nil {
			log.Printf("No %s found in database to sync", task.Name)
			continue
		}
		if err := e.syncEntities(ctx, task.Name, task.Entities); err != nil {
			log.Printf("Failed to sync %s: %v", task.Name, err)
		}
	}

	log.Println("Completed synchronization of database to Elasticsearch")
	return nil
}

// =============================
// 核心方法：同步单个实体类型
// =============================

func (e *ElasticSearchConfig) syncEntities(ctx context.Context, entityType string, entities interface{}) error {
	items, ok := entities.([]Entity)
	if !ok {
		return fmt.Errorf("invalid entity type for %s", entityType)
	}

	for _, entity := range items {
		doc := entity.ToDocument()

		body, err := json.Marshal(doc)
		if err != nil {
			log.Printf("Failed to marshal %s (ID=%v): %v", entityType, entity.GetID(), err)
			continue
		}

		res, err := e.Client.Index(
			entityType,
			bytes.NewReader(body),
			e.Client.Index.WithDocumentID(fmt.Sprintf("%v", entity.GetID())),
			e.Client.Index.WithContext(ctx),
		)
		if err != nil {
			log.Printf("Failed to index %s (ID=%v): %v", entityType, entity.GetID(), err)
			continue
		}
		defer func(Body io.ReadCloser) {
			err := Body.Close()
			if err != nil {
				log.Printf("Failed to close Body: %v", err)
			}
		}(res.Body)

		if res.IsError() {
			log.Printf("Failed to index %s (ID=%v): %s", entityType, entity.GetID(), res.String())
		} else {
			log.Printf("Synced %s with ID=%v to Elasticsearch", entityType, entity.GetID())
		}
	}
	return nil
}

// =============================
// 数据模型和接口定义
// =============================

// Entity 接口：每个实体类型都需要实现这三个方法
type Entity interface {
	GetID() any
	ToDocument() interface{}
}

// DataSource 模拟你的 Mapper 层（MyBatis）
type DataSource interface {
	GetVehicles() []Entity
	GetDrivers() []Entity
	GetOffenses() []Entity
	GetAppeals() []Entity
	GetFines() []Entity
	GetDeductions() []Entity
	GetOffenseDetails() []Entity
	GetUsers() []Entity
	GetLoginLogs() []Entity
	GetOperationLogs() []Entity
	GetSystemLogs() []Entity
}

// =============================
// 模拟的数据库和实体实现
// =============================

// VehicleInformation ---- 示例实体：VehicleInformation ----
type VehicleInformation struct {
	ID    int    `json:"vehicle_id"`
	Plate string `json:"plate"`
}

func (v VehicleInformation) GetID() any              { return v.ID }
func (v VehicleInformation) ToDocument() interface{} { return v } // 可在此处做字段映射转换

// MockDataSource ---- 示例数据源实现 ----
type MockDataSource struct{}

func (ds MockDataSource) GetVehicles() []Entity {
	return []Entity{
		VehicleInformation{ID: 1, Plate: "A12345"},
		VehicleInformation{ID: 2, Plate: "B67890"},
	}
}

func (ds MockDataSource) GetDrivers() []Entity        { return nil }
func (ds MockDataSource) GetOffenses() []Entity       { return nil }
func (ds MockDataSource) GetAppeals() []Entity        { return nil }
func (ds MockDataSource) GetFines() []Entity          { return nil }
func (ds MockDataSource) GetDeductions() []Entity     { return nil }
func (ds MockDataSource) GetOffenseDetails() []Entity { return nil }
func (ds MockDataSource) GetUsers() []Entity          { return nil }
func (ds MockDataSource) GetLoginLogs() []Entity      { return nil }
func (ds MockDataSource) GetOperationLogs() []Entity  { return nil }
func (ds MockDataSource) GetSystemLogs() []Entity     { return nil }

// =============================
// 启动入口
// =============================

func main() {
	db := MockDataSource{}
	esURI := os.Getenv("ELASTIC_URI")
	if esURI == "" {
		esURI = "http://localhost:9200"
	}

	esConfig, err := NewElasticSearchConfig(esURI, db)
	if err != nil {
		log.Fatalf("Failed to init Elasticsearch config: %v", err)
	}

	if err := esConfig.SyncDatabaseToElasticsearch(); err != nil {
		log.Fatalf("Sync failed: %v", err)
	}
}
