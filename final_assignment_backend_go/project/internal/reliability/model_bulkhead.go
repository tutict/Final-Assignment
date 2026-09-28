package reliability

// ModelBulkhead limits in-flight model calls for this process.
// A full gate returns immediately so the caller can degrade.
type ModelBulkhead struct {
	slots chan struct{}
}

func NewModelBulkhead(maxInFlight int) *ModelBulkhead {
	if maxInFlight < 0 {
		maxInFlight = 2
	}
	return &ModelBulkhead{slots: make(chan struct{}, maxInFlight)}
}

func (b *ModelBulkhead) TryAcquire() bool {
	if b == nil || b.slots == nil {
		return true
	}
	select {
	case b.slots <- struct{}{}:
		return true
	default:
		return false
	}
}

func (b *ModelBulkhead) Release() {
	if b == nil || b.slots == nil {
		return
	}
	select {
	case <-b.slots:
	default:
	}
}
