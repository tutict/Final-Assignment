package docker

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/elasticsearch"
	"github.com/testcontainers/testcontainers-go/modules/redis"
	"github.com/testcontainers/testcontainers-go/wait"
)

// RunDocker 结构体用于管理所有容器
type RunDocker struct {
	ctx                    context.Context
	redisContainer         *redis.RedisContainer
	redpandaContainer      testcontainers.Container
	elasticsearchContainer *elasticsearch.ElasticsearchContainer
	manticoreContainer     testcontainers.Container
}

// NewRunDocker 初始化一个新的实例
func NewRunDocker() *RunDocker {
	return &RunDocker{ctx: context.Background()}
}

// Init 启动所有容器
func (r *RunDocker) Init() {
	r.startRedis()
	r.startRedpanda()
	r.startElasticsearch()
	// r.startManticoreSearch()
}

// startRedis 启动 Redis 容器
func (r *RunDocker) startRedis() {
	log.Println("[INFO] Starting Redis container...")
	container, err := redis.RunContainer(r.ctx,
		testcontainers.WithImage("redis:7"),
	)
	if err != nil {
		log.Printf("[ERROR] Failed to start Redis: %v\n", err)
		return
	}

	host, _ := container.Host(r.ctx)
	port, _ := container.MappedPort(r.ctx, "6379/tcp")

	err = os.Setenv("REDIS_HOST", host)
	if err != nil {
		return
	}

	err = os.Setenv("REDIS_PORT", port.Port())
	if err != nil {
		return
	}

	log.Printf("[INFO] Redis started at %s:%s\n", host, port.Port())

	r.redisContainer = container
}

// startRedpanda 启动 Redpanda 容器
func (r *RunDocker) startRedpanda() {
	log.Println("[INFO] Starting Redpanda container...")
	req := testcontainers.ContainerRequest{
		Image:        "redpandadata/redpanda:v24.1.2",
		ExposedPorts: []string{"9092/tcp"},
		WaitingFor:   wait.ForLog("Started Kafka API server").WithStartupTimeout(2 * time.Minute),
	}
	container, err := testcontainers.GenericContainer(r.ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		log.Printf("[ERROR] Failed to start Redpanda: %v\n", err)
		return
	}

	host, _ := container.Host(r.ctx)
	port, _ := container.MappedPort(r.ctx, "9092/tcp")
	bootstrap := fmt.Sprintf("%s:%s", host, port.Port())

	err = os.Setenv("KAFKA_BOOTSTRAP_SERVERS", bootstrap)
	if err != nil {
		return
	}

	log.Printf("[INFO] Redpanda started, bootstrap servers: %s\n", bootstrap)

	r.redpandaContainer = container
}

// startElasticsearch 启动 Elasticsearch 容器
func (r *RunDocker) startElasticsearch() {
	log.Println("[INFO] Starting Elasticsearch container...")

	container, err := elasticsearch.RunContainer(r.ctx,
		testcontainers.WithImage("tutict/elasticsearch-with-plugins:8.17.3-for-my-work"),
		testcontainers.WithEnv(map[string]string{
			"xpack.security.enabled": "false",
			"discovery.type":         "single-node",
		}),
	)
	if err != nil {
		log.Printf("[ERROR] Failed to start Elasticsearch: %v\n", err)
		return
	}

	host, _ := container.Host(r.ctx)
	port, _ := container.MappedPort(r.ctx, "9200/tcp")

	url := fmt.Sprintf("http://%s:%s", host, port.Port())

	err = os.Setenv("ELASTICSEARCH_URL", url)
	if err != nil {
		return
	}

	log.Printf("[INFO] Elasticsearch started at: %s\n", url)
	r.elasticsearchContainer = container
}

// startManticoreSearch 启动 Manticore Search 容器
func (r *RunDocker) startManticoreSearch() {
	log.Println("[INFO] Starting Manticore Search container...")

	req := testcontainers.ContainerRequest{
		Image:        "manticoresearch/manticore:dev",
		ExposedPorts: []string{"9306/tcp", "9308/tcp"},
		Env:          map[string]string{"EXTRA": "1"},
		WaitingFor: wait.ForHTTP("/search").
			WithPort("9308/tcp").
			WithStartupTimeout(2 * time.Minute),
	}

	container, err := testcontainers.GenericContainer(r.ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		log.Printf("[ERROR] Failed to start Manticore: %v\n", err)
		return
	}

	host, _ := container.Host(r.ctx)
	port, _ := container.MappedPort(r.ctx, "9308/tcp")
	url := fmt.Sprintf("http://%s:%s", host, port.Port())

	err = os.Setenv("MANTICORE_URL", url)
	if err != nil {
		return
	}
	log.Printf("[INFO] Manticore started at: %s\n", url)

	r.manticoreContainer = container
}

// StopContainers 停止所有容器
func (r *RunDocker) StopContainers() {
	if r.redisContainer != nil {
		err := r.redisContainer.Terminate(r.ctx)
		if err != nil {
			return
		}
		log.Println("[INFO] Redis container stopped")
	}
	if r.redpandaContainer != nil {
		err := r.redpandaContainer.Terminate(r.ctx)
		if err != nil {
			return
		}
		log.Println("[INFO] Redpanda container stopped")
	}
	if r.elasticsearchContainer != nil {

		err := r.elasticsearchContainer.Terminate(r.ctx)
		if err != nil {
			return
		}
		log.Println("[INFO] Elasticsearch container stopped")
	}
	if r.manticoreContainer != nil {

		err := r.manticoreContainer.Terminate(r.ctx)
		if err != nil {
			return
		}
		log.Println("[INFO] Manticore container stopped")
	}
}
