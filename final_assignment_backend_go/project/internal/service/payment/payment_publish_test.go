package payment

import (
	"errors"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/reliability"
)

func TestPublishFailureIsCountedAndDoesNotEscape(t *testing.T) {
	before := reliability.KafkaPublishFailedCount()
	previous := publishPaymentCreated
	publishPaymentCreated = func(key string, payment *domain.PaymentRecord) error {
		if key != "pay-1" || payment.PaymentID != 9 {
			t.Fatalf("unexpected publish key=%s id=%d", key, payment.PaymentID)
		}
		return errors.New("down")
	}
	t.Cleanup(func() { publishPaymentCreated = previous })
	publishAfterCommit("pay-1", &domain.PaymentRecord{PaymentID: 9})
	if got := reliability.KafkaPublishFailedCount(); got != before+1 {
		t.Fatalf("kafka_publish_failed_total = %d, want %d", got, before+1)
	}
}

func TestPaymentProducerStaysInsideDeliveryTimeout(t *testing.T) {
	if paymentProducerRetries != 3 {
		t.Fatalf("retries=%d, want 3", paymentProducerRetries)
	}
	if paymentProducerDeliveryTimeout != 10*time.Second {
		t.Fatalf("delivery timeout=%s, want 10s", paymentProducerDeliveryTimeout)
	}
	if paymentProducerRequestTimeout > 3*time.Second {
		t.Fatalf("per-request timeout %s is above the 3s request bound", paymentProducerRequestTimeout)
	}
	if !paymentProducerIdempotent {
		t.Fatal("payment producer must stay idempotent")
	}
	opts := paymentClientOptions()
	if len(opts) < 6 {
		t.Fatalf("options=%d", len(opts))
	}
	client, err := paymentClient()
	if err != nil {
		t.Fatal(err)
	}
	if client == nil {
		t.Fatal("missing payment client")
	}
}
