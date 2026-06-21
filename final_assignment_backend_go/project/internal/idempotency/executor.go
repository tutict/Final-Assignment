package idempotency

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// Executor handles idempotent execution of operations
type Executor struct {
	store             Store
	processingTTL     time.Duration
	completedTTL      time.Duration
	retryAfterTimeout time.Duration
}

// NewExecutor creates a new idempotent executor
func NewExecutor(store Store) *Executor {
	return &Executor{
		store:             store,
		processingTTL:     5 * time.Minute,  // Processing timeout
		completedTTL:      24 * time.Hour,   // Result cache duration
		retryAfterTimeout: 30 * time.Second, // Retry after this if processing
	}
}

// WithProcessingTTL sets the processing TTL
func (ie *Executor) WithProcessingTTL(ttl time.Duration) *Executor {
	ie.processingTTL = ttl
	return ie
}

// WithCompletedTTL sets the completed TTL
func (ie *Executor) WithCompletedTTL(ttl time.Duration) *Executor {
	ie.completedTTL = ttl
	return ie
}

// Execute executes an action idempotently
func (ie *Executor) Execute(
	ctx context.Context,
	idempotencyKey string,
	action func() (interface{}, error),
) (interface{}, error) {
	// 1. Check if already completed
	result, completed, err := ie.store.GetResult(ctx, idempotencyKey)
	if err != nil {
		return nil, fmt.Errorf("failed to get result: %w", err)
	}

	if completed {
		// Return cached result
		return result, nil
	}

	// 2. Try to mark as processing
	ok, err := ie.store.MarkProcessing(ctx, idempotencyKey, ie.processingTTL)
	if err != nil {
		return nil, fmt.Errorf("failed to mark processing: %w", err)
	}

	if !ok {
		// Already processing by another request
		return nil, ErrAlreadyProcessing
	}

	// 3. Execute action
	result, err = action()
	if err != nil {
		// On error, delete the processing marker to allow retry
		ie.store.Delete(ctx, idempotencyKey)
		return nil, err
	}

	// 4. Store result
	if err := ie.store.MarkCompleted(ctx, idempotencyKey, result, ie.completedTTL); err != nil {
		return nil, fmt.Errorf("failed to mark completed: %w", err)
	}

	return result, nil
}

// ExecuteWithRetry executes with automatic retry on ErrAlreadyProcessing
func (ie *Executor) ExecuteWithRetry(
	ctx context.Context,
	idempotencyKey string,
	action func() (interface{}, error),
	maxRetries int,
) (interface{}, error) {
	var lastErr error

	for i := 0; i <= maxRetries; i++ {
		result, err := ie.Execute(ctx, idempotencyKey, action)

		if err == nil {
			return result, nil
		}

		if !errors.Is(err, ErrAlreadyProcessing) {
			// Non-retryable error
			return nil, err
		}

		lastErr = err

		// Wait before retry
		if i < maxRetries {
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			case <-time.After(ie.retryAfterTimeout):
				// Try again
			}
		}
	}

	return nil, lastErr
}

// KafkaProcessor handles idempotent Kafka message processing
type KafkaProcessor struct {
	executor *Executor
}

// NewKafkaProcessor creates a new Kafka idempotency processor
func NewKafkaProcessor(store Store) *KafkaProcessor {
	return &KafkaProcessor{
		executor: NewExecutor(store).
			WithProcessingTTL(10 * time.Minute).
			WithCompletedTTL(7 * 24 * time.Hour), // Keep for 7 days
	}
}

// Process processes a Kafka message idempotently
func (kp *KafkaProcessor) Process(
	ctx context.Context,
	messageKey string,
	handler func() error,
) error {
	_, err := kp.executor.Execute(ctx, messageKey, func() (interface{}, error) {
		if err := handler(); err != nil {
			return nil, err
		}
		return "success", nil
	})

	return err
}

// IsAlreadyProcessed checks if a message was already processed
func (kp *KafkaProcessor) IsAlreadyProcessed(ctx context.Context, messageKey string) (bool, error) {
	_, completed, err := kp.executor.store.GetResult(ctx, messageKey)
	return completed, err
}
