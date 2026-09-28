package reliability

import "time"

type Outcome int

const (
	Insert Outcome = iota
	Replay
	Conflict
	InProgress
	Retry
)

const ProcessingTTL = 2 * time.Minute

func Decide(exists bool, status, stored, incoming string, age time.Duration) Outcome {
	if !exists {
		return Insert
	}
	switch status {
	case "FAILED", "failed":
		return Retry
	case "PROCESSING", "processing":
		if age >= ProcessingTTL {
			return Retry
		}
		return InProgress
	case "SUCCESS", "success":
		if samePayload(stored, incoming) {
			return Replay
		}
		return Conflict
	default:
		return Conflict
	}
}

func samePayload(stored, incoming string) bool {
	if incoming == "" {
		return true
	}
	if stored == "" || stored == "DONE" {
		return true
	}
	return stored == incoming
}