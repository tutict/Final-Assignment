# TASK-002: Spring Idempotent Appeal Creation

## Owner Role

Backend Worker after TASK-001 integration.

## Allowed Scope

Spring files owned: `AppealManagementController.java`, `AppealRecordService.java`,
`AppealWorkflowOrchestrator.java`, `AppealRecordApplicationService.java`,
`AppealIdempotencyService.java`, `AppealBusinessPolicy.java`,
`SysRequestHistoryMapper.java`, plus focused appeal backend test files. Existing
direct create-event publication may be removed from this path; unrelated
listeners and workflow behavior remain out of scope. No schema or migration
edits.

## Deliverable

Implement S-1..S-8: one authenticated operation/history/appeal outcome,
transactional atomicity, deterministic HTTP 208 duplicate success, same-body/user
validation, new-key behavior, response-read retry safety, concurrency safety, and
existing workflow compatibility.

The duplicate HTTP 208 response must preserve `ApiResponse.ok(null)`, while the
service validates or retrieves the durable business result. History may store a
non-sensitive request fingerprint and authenticated user ID; it must not persist
raw identity-card or contact data.

## Forbidden

No Flutter or React edits, no unrelated backend, no auth redesign, no dependency
changes, no authoritative Ledger edits, and no parent completion announcement.

## Acceptance Evidence

Focused unit/controller/integration tests as feasible, including authenticated
identity, duplicate result, one row, different key, and race/transaction behavior.
Use the fixed database `traffic_exp006_full_loop` for database integration.
