package statemachine

import "testing"

func TestAppealStatusUpdatesIncludeReasonOnlyWhenRejected(t *testing.T) {
	rejected := appealStatusUpdates(AppealStateRejected, "  证据不足  ")
	if rejected["process_status"] != AppealStateRejected {
		t.Fatalf("process_status=%v want %s", rejected["process_status"], AppealStateRejected)
	}
	if rejected["rejection_reason"] != "证据不足" {
		t.Fatalf("rejection_reason=%v want 证据不足", rejected["rejection_reason"])
	}

	approved := appealStatusUpdates(AppealStateApproved, "不应写入")
	if _, ok := approved["rejection_reason"]; ok {
		t.Fatalf("approved transition must not write rejection_reason: %v", approved)
	}

	blank := appealStatusUpdates(AppealStateRejected, "   ")
	if _, ok := blank["rejection_reason"]; ok {
		t.Fatalf("blank reason must not overwrite rejection_reason: %v", blank)
	}
}
