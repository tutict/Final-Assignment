package idempotency

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestExecutor_Execute_Success(t *testing.T) {
	store := NewMemoryStore()
	executor := NewExecutor(store)

	ctx := context.Background()
	key := "test-key-1"

	callCount := 0
	action := func() (interface{}, error) {
		callCount++
		return "success-result", nil
	}

	// First execution
	result, err := executor.Execute(ctx, key, action)
	if err != nil {
		t.Fatalf("Execute() error = %v", err)
	}

	if result != "success-result" {
		t.Errorf("Result = %v, want success-result", result)
	}

	if callCount != 1 {
		t.Errorf("Action called %d times, want 1", callCount)
	}

	// Second execution (should return cached result)
	result, err = executor.Execute(ctx, key, action)
	if err != nil {
		t.Fatalf("Execute() error = %v", err)
	}

	if result != "success-result" {
		t.Errorf("Result = %v, want success-result", result)
	}

	if callCount != 1 {
		t.Errorf("Action called %d times after second execute, want 1 (cached)", callCount)
	}
}

func TestExecutor_Execute_Error(t *testing.T) {
	store := NewMemoryStore()
	executor := NewExecutor(store)

	ctx := context.Background()
	key := "test-key-error"

	expectedErr := errors.New("action failed")
	action := func() (interface{}, error) {
		return nil, expectedErr
	}

	// First execution (should fail)
	_, err := executor.Execute(ctx, key, action)
	if err == nil {
		t.Fatal("Execute() should return error")
	}

	if !errors.Is(err, expectedErr) {
		t.Errorf("Execute() error = %v, want %v", err, expectedErr)
	}

	// Should allow retry after error
	callCount := 0
	retryAction := func() (interface{}, error) {
		callCount++
		return "retry-success", nil
	}

	result, err := executor.Execute(ctx, key, retryAction)
	if err != nil {
		t.Fatalf("Execute() retry error = %v", err)
	}

	if result != "retry-success" {
		t.Errorf("Result = %v, want retry-success", result)
	}

	if callCount != 1 {
		t.Errorf("Retry action called %d times, want 1", callCount)
	}
}

func TestExecutor_Execute_AlreadyProcessing(t *testing.T) {
	store := NewMemoryStore()
	executor := NewExecutor(store)

	ctx := context.Background()
	key := "test-key-concurrent"

	// Manually mark as processing
	store.MarkProcessing(ctx, key, 1*time.Minute)

	action := func() (interface{}, error) {
		return "result", nil
	}

	// Should fail with ErrAlreadyProcessing
	_, err := executor.Execute(ctx, key, action)
	if !errors.Is(err, ErrAlreadyProcessing) {
		t.Errorf("Execute() error = %v, want ErrAlreadyProcessing", err)
	}
}

func TestExecutor_ExecuteWithRetry(t *testing.T) {
	store := NewMemoryStore()
	executor := NewExecutor(store).WithProcessingTTL(100 * time.Millisecond)

	ctx := context.Background()
	key := "test-key-retry"

	// Mark as processing with short TTL
	store.MarkProcessing(ctx, key, 100*time.Millisecond)

	action := func() (interface{}, error) {
		return "retry-result", nil
	}

	// Execute with retry (should eventually succeed after TTL expires)
	result, err := executor.ExecuteWithRetry(ctx, key, action, 1)
	if err != nil {
		t.Fatalf("ExecuteWithRetry() error = %v", err)
	}

	if result != "retry-result" {
		t.Errorf("Result = %v, want retry-result", result)
	}
}

func TestExecutor_CustomTTL(t *testing.T) {
	store := NewMemoryStore()
	executor := NewExecutor(store).
		WithProcessingTTL(1 * time.Second).
		WithCompletedTTL(5 * time.Second)

	if executor.processingTTL != 1*time.Second {
		t.Errorf("ProcessingTTL = %v, want 1s", executor.processingTTL)
	}

	if executor.completedTTL != 5*time.Second {
		t.Errorf("CompletedTTL = %v, want 5s", executor.completedTTL)
	}
}

func TestKafkaProcessor_Process(t *testing.T) {
	store := NewMemoryStore()
	processor := NewKafkaProcessor(store)

	ctx := context.Background()
	messageKey := "kafka-msg-1"

	callCount := 0
	handler := func() error {
		callCount++
		return nil
	}

	// First processing
	err := processor.Process(ctx, messageKey, handler)
	if err != nil {
		t.Fatalf("Process() error = %v", err)
	}

	if callCount != 1 {
		t.Errorf("Handler called %d times, want 1", callCount)
	}

	// Second processing (should be idempotent)
	err = processor.Process(ctx, messageKey, handler)
	if err != nil {
		t.Fatalf("Process() second call error = %v", err)
	}

	if callCount != 1 {
		t.Errorf("Handler called %d times after second process, want 1 (idempotent)", callCount)
	}
}

func TestKafkaProcessor_ProcessError(t *testing.T) {
	store := NewMemoryStore()
	processor := NewKafkaProcessor(store)

	ctx := context.Background()
	messageKey := "kafka-msg-error"

	expectedErr := errors.New("processing failed")
	handler := func() error {
		return expectedErr
	}

	// Should return error
	err := processor.Process(ctx, messageKey, handler)
	if !errors.Is(err, expectedErr) {
		t.Errorf("Process() error = %v, want %v", err, expectedErr)
	}

	// Should allow retry after error
	callCount := 0
	retryHandler := func() error {
		callCount++
		return nil
	}

	err = processor.Process(ctx, messageKey, retryHandler)
	if err != nil {
		t.Fatalf("Process() retry error = %v", err)
	}

	if callCount != 1 {
		t.Errorf("Retry handler called %d times, want 1", callCount)
	}
}

func TestKafkaProcessor_IsAlreadyProcessed(t *testing.T) {
	store := NewMemoryStore()
	processor := NewKafkaProcessor(store)

	ctx := context.Background()
	messageKey := "kafka-msg-check"

	// Not processed yet
	processed, err := processor.IsAlreadyProcessed(ctx, messageKey)
	if err != nil {
		t.Fatalf("IsAlreadyProcessed() error = %v", err)
	}
	if processed {
		t.Error("IsAlreadyProcessed() = true, want false for new message")
	}

	// Process it
	handler := func() error {
		return nil
	}
	processor.Process(ctx, messageKey, handler)

	// Should be processed now
	processed, err = processor.IsAlreadyProcessed(ctx, messageKey)
	if err != nil {
		t.Fatalf("IsAlreadyProcessed() error = %v", err)
	}
	if !processed {
		t.Error("IsAlreadyProcessed() = false, want true after processing")
	}
}

func TestMemoryStore_Expiration(t *testing.T) {
	store := NewMemoryStore()
	ctx := context.Background()

	key := "expire-test"
	ttl := 100 * time.Millisecond

	// Mark processing with short TTL
	ok, _ := store.MarkProcessing(ctx, key, ttl)
	if !ok {
		t.Fatal("MarkProcessing() should succeed")
	}

	// Should exist immediately
	_, completed, _ := store.GetResult(ctx, key)
	if completed {
		t.Error("Should be processing, not completed")
	}

	// Wait for expiration
	time.Sleep(150 * time.Millisecond)

	// Should be able to mark processing again (expired)
	ok, _ = store.MarkProcessing(ctx, key, ttl)
	if !ok {
		t.Error("MarkProcessing() should succeed after expiration")
	}
}

func TestMemoryStore_Delete(t *testing.T) {
	store := NewMemoryStore()
	ctx := context.Background()

	key := "delete-test"

	// Mark processing
	store.MarkProcessing(ctx, key, 1*time.Minute)

	// Verify exists
	_, completed, _ := store.GetResult(ctx, key)
	if completed {
		t.Error("Should be processing")
	}

	// Delete
	err := store.Delete(ctx, key)
	if err != nil {
		t.Fatalf("Delete() error = %v", err)
	}

	// Verify deleted
	result, completed, _ := store.GetResult(ctx, key)
	if result != nil || completed {
		t.Error("Key should be deleted")
	}
}

func TestMemoryStore_Clear(t *testing.T) {
	store := NewMemoryStore()
	ctx := context.Background()

	// Add multiple entries
	store.MarkProcessing(ctx, "key1", 1*time.Minute)
	store.MarkProcessing(ctx, "key2", 1*time.Minute)
	store.MarkCompleted(ctx, "key3", "result", 1*time.Minute)

	if len(store.data) != 3 {
		t.Errorf("Store size = %d, want 3", len(store.data))
	}

	// Clear all
	store.Clear()

	if len(store.data) != 0 {
		t.Errorf("Store size after clear = %d, want 0", len(store.data))
	}
}
