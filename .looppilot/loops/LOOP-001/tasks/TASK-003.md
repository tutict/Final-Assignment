# TASK-003: Flutter Appeal Operation Lifecycle

## Owner Role

Frontend Worker after TASK-001 integration.

## Allowed Scope

Flutter files owned: `appeal_management_controller_api.dart`,
`user_appeal.dart`, one new appeal operation-lifecycle helper if useful, and
focused Dart tests. Network base code may change only if the appeal-specific
nullable 208 contract cannot be expressed through existing helpers. No dependency
changes.

## Deliverable

Implement F-1..F-9: one key per logical operation, same key on transient retry,
pending duplicate suppression, safe HTTP 208 nullable-data duplicate success,
terminal/transient/cancel release rules, and a new key for a new operation.

The existing Spring duplicate shape is HTTP 208 with successful envelope and
nullable data. Do not manufacture an `AppealRecordModel` for that response.

## Forbidden

No backend or React edits, no global auth redesign, no dependency changes, no
authoritative Ledger edits, and no parent completion announcement.

## Acceptance Evidence

Focused Dart tests exercising pending, transient, validation, cancel, success,
processed duplicate, 208 nullable data, and new-operation cases.
