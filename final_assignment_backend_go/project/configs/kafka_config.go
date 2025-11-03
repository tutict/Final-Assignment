package config

import (
	"context"
	"log"
	"time"

	"github.com/segmentio/kafka-go"
)

// KafkaConfig 保存 Kafka 连接配置
type KafkaConfig struct {
	BootstrapServers string
	GroupID          string
	Topic            string
}

// NewKafkaReader 创建一个新的 Kafka 消费者（类似于 Java 中的 KafkaConsumer Bean）
func NewKafkaReader(cfg KafkaConfig) *kafka.Reader {
	if cfg.BootstrapServers == "" {
		log.Fatal("Kafka bootstrap servers must not be empty")
	}

	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:     []string{cfg.BootstrapServers},
		GroupID:     cfg.GroupID,
		Topic:       cfg.Topic,
		Partition:   0,
		MinBytes:    1,                 // 最小批次大小
		MaxBytes:    10e6,              // 最大批次大小（10MB）
		StartOffset: kafka.FirstOffset, // 相当于 auto.offset.reset=earliest
	})
	log.Printf("Kafka consumer initialized for topic: %s", cfg.Topic)
	return reader
}

// ConsumeMessages 启动消费者循环（模拟 Java Vertx KafkaConsumer 的异步特性）
func ConsumeMessages(ctx context.Context, reader *kafka.Reader, handler func(key, value string)) {
	for {
		m, err := reader.ReadMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				log.Println("Kafka consumer stopped gracefully.")
				return
			}
			log.Printf("Error reading message: %v", err)
			time.Sleep(2 * time.Second)
			continue
		}

		log.Printf("Consumed message: key=%s value=%s partition=%d offset=%d",
			string(m.Key), string(m.Value), m.Partition, m.Offset)

		// 执行业务逻辑
		handler(string(m.Key), string(m.Value))
	}
}
