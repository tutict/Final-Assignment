package payment

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"strings"
	"sync"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/reliability"

	"github.com/twmb/franz-go/pkg/kgo"
)

const paymentTopic = "payment_record_create"

const (
	paymentProducerRetries         = 3
	paymentProducerRequestTimeout  = 2 * time.Second
	paymentProducerDeliveryTimeout = 10 * time.Second
)

// paymentProducerIdempotent is the switch for Kafka's idempotent producer.
// franz-go enables it unless DisableIdempotentWrite is added. kafka-go 0.4.51
// writes producer id -1 and cannot.
const paymentProducerIdempotent = true

var publishPaymentCreated = func(key string, payment *domain.PaymentRecord) error {
	body, err := json.Marshal(payment)
	if err != nil {
		return err
	}
	client, err := paymentClient()
	if err != nil {
		return err
	}
	client.Produce(context.Background(), &kgo.Record{
		Topic: paymentTopic,
		Key:   []byte(key),
		Value: body,
	}, func(_ *kgo.Record, err error) {
		if err != nil {
			reliability.NoteKafkaPublishFailed()
		}
	})
	return nil
}

func publishAfterCommit(key string, payment *domain.PaymentRecord) {
	if publishPaymentCreated == nil || payment == nil {
		return
	}
	if err := publishPaymentCreated(key, payment); err != nil {
		reliability.NoteKafkaPublishFailed()
	}
}

func paymentBrokers() []string {
	raw := os.Getenv("KAFKA_BOOTSTRAP_SERVERS")
	parts := strings.Split(raw, ",")
	brokers := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			brokers = append(brokers, part)
		}
	}
	if len(brokers) == 0 {
		return []string{"localhost:9092"}
	}
	return brokers
}

func paymentClientOptions() []kgo.Opt {
	opts := []kgo.Opt{
		kgo.SeedBrokers(paymentBrokers()...),
		kgo.DefaultProduceTopic(paymentTopic),
		kgo.RequiredAcks(kgo.AllISRAcks()),
		kgo.RecordRetries(paymentProducerRetries),
		kgo.ProduceRequestTimeout(paymentProducerRequestTimeout),
		kgo.RecordDeliveryTimeout(paymentProducerDeliveryTimeout),
		kgo.ProducerBatchCompression(kgo.NoCompression()),
	}
	if !paymentProducerIdempotent {
		opts = append(opts, kgo.DisableIdempotentWrite())
	}
	return opts
}

var (
	clientOnce sync.Once
	client     *kgo.Client
	clientErr  error
)

func paymentClient() (*kgo.Client, error) {
	clientOnce.Do(func() {
		client, clientErr = kgo.NewClient(paymentClientOptions()...)
	})
	if clientErr != nil {
		return nil, clientErr
	}
	if client == nil {
		return nil, errors.New("payment kafka client is not initialized")
	}
	return client, nil
}
