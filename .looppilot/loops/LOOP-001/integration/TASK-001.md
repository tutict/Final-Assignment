# TASK-001 Integration

## Observed Inputs

- The bounded delivery maps all fixed S-1..S-8 and F-1..F-9 criteria to local
  Spring/Flutter boundaries and labels observed, inferred, expected, and
  unverified claims.
- The persisted independent review records Spec PASS, Standards PASS, no
  blocking findings, and TASK-002/003 readiness READY.
- The Reviewer records INFO-001: Delivery submitter attribution is unavailable;
  it remains preserved as unattributed and is not credited to EII-001.
- `git diff --check` passed after the delivery and review artifacts appeared.
- No product file changed during TASK-001.

## Supervisor Decisions

- S-6 authenticated identity means Spring owns `createdBy`/`updatedBy` and the
  regular-user driver relationship from the authenticated profile. Appellant
  claim fields remain request data subject to validation; they are not accepted
  as the authentication principal.
- Preserve the existing HTTP 208 `ApiResponse.ok(null)` duplicate shape so
  Flutter must safely accept nullable duplicate data; backend must still
  recover/validate the durable business result before returning it.
- Direct `POST /api/appeals` must not create a second appeal through asynchronous
  create-event replay. TASK-002 may remove that create publication from this path
  without changing unrelated Kafka workflow behavior.
- Response-read loss evidence will be modeled, not described as live TCP proof.

## Ownership Handoff

- TASK-002 owns Spring controller/service/application/idempotency/policy/mapper
  code and backend appeal tests only.
- TASK-003 owns Flutter appeal API, one focused operation-lifecycle helper, the
  appeal dialog call site, and focused Dart tests only.
- Core ownership is disjoint. TASK-004 remains blocked until both are integrated.
