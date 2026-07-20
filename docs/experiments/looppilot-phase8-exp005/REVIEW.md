# EXP-005 Review Record — Lightweight Dual-Axis + Security

Change under review: client session-recovery classification
(CHANGE-CONTRACT.md). Reviews were INDEPENDENT delegated agents, each
read-only, findings-only (no reviewer modified the implementation).
Contrast point vs MMGH EXP-002 (which used Supervisor self-review):
EXP-005 exercised genuinely independent review under Lightweight.

## Verdict summary

| Axis | Reviewer | Verdict | Major/Blocker | Minor | Info |
| --- | --- | --- | --- | --- | --- |
| Spec | independent agent | PASS-WITH-FINDINGS | 0 | 7 (M1–M7) | 0 |
| Standards | independent agent | PASS-WITH-FINDINGS | 0 | 3 (F1–F3) | 0 |
| Security (risk-loaded) | independent agent | PASS-WITH-FINDINGS | 0 | 2 (SF1–SF2) | 2 (SF3–SF4) |

No Major or Blocker finding → no Lightweight escalation trigger fired.
All findings were registered here before any correction was made.

## Spec findings and dispositions

- M1 transient is a catch-all superset of the contract's enumerated statuses
  (auth_service.dart) — **fixed in contract text**: unlisted statuses default
  to transient, fail-safe by design (only an explicit server refusal may
  destroy tokens). Code unchanged (direction already conservative).
- M2 5xx-expired test did not assert access-token preservation — **fixed in
  test** (assert added; suite re-run green).
- M3 `redirectIfInvalid: true` path unexercised — **recorded, not fixed**:
  a VM unit test would need a 5-second Get-context wait loop or the full app
  route table; the redirect path is unchanged from baseline except the
  clearStoredTokens:false flag. Residual test gap.
- M4 "clears-once" count and missing-token cleanup unasserted — **partially
  fixed**: missing-token test now asserts cleanup; call-count remains
  unasserted (clearTokens is idempotent; count not observable through the
  public seam without adding product test hooks). Residual.
- M5 contract overstated what the new tests pin — **fixed in contract text**
  (pinned: logout cleanup, single-flight; review-verified untouched:
  blacklist, storage, redirect guard).
- M6 BASELINE-OBSERVATIONS correction was a fifth touched file outside the
  enumerated scope — **fixed in contract text**: governance/evidence docs may
  receive factual corrections; evidence honesty outranks scope-list
  stability for non-product files.
- M7 blank-token 400-vs-401 pinned only as anyOf; rotated-reuse not re-pinned
  in the new class — **recorded**: rotated-reuse→401 is pinned by pre-existing
  AuthIntegrationTest (order-5), green in the corrected environment;
  duplication adds no information.

## Standards findings and dispositions

- F1 pre-existing `.gitignore` delta co-mingled in working tree —
  **addressed**: contract now states it stays excluded and staging is
  explicit-path only (practice already followed in commit 1).
- F2 contract said "internal" classification but the seam is public —
  **fixed in contract text**: "library-level (public)" with the Case-2
  adoption rationale.
- F3 status enumeration duplicated in two doc comments — **fixed in code
  comment**: enum doc now semantic-only; the status decision lives solely at
  `_isTerminalRefreshRejection`.

## Security findings and dispositions (risk-loaded axis)

- SF1 (Minor) longer at-rest retention window for refresh-token material
  under attacker-forgeable transient responses (bounded by untouched
  server-side 7-day TTL, single-use rotation, revocation; exploitation
  requires device-storage compromise) — **accepted**: inherent, contracted
  cost of removing the forced-logout availability lever; recorded in
  RESULTS.
- SF2 (Minor) bounded linear refresh amplification during sustained outage
  (≤2 refresh POSTs per caller-driven call within the skew window; no client
  backoff; Retry-After unused) — **accepted as residual**, coupled to the
  already-recorded A-G2 exclusion; no unbounded loop exists (test-pinned
  refreshCalls==1 per attempt).
- SF3 (Info, pre-existing) catch blocks log raw error objects that can embed
  response-body fragments — unchanged from baseline; recorded.
- SF4 (Info) missing-token test pinned only the boolean — **fixed** together
  with M4 (cleanup now asserted).
- Security net assessment (reviewer's): posture improves — the change removes
  a cheap forced-logout attack lever (one spoofed 503 destroyed a valid
  session); terminal cleanup preserved on all traced paths and now
  test-pinned; no control weakened; no new log leakage.

## Reviewer reverification

Corrections (M1/M2/M4-part/M5/M6, F1/F2/F3, SF4) were sent back to the
ORIGINAL Spec and Standards reviewers, who reverified the actual files:

- Spec reverification: **VERIFIED — verdict stands PASS-WITH-FINDINGS** with
  M3 and M7 as recorded Minor residuals; every applied fix confirmed
  line-by-line; no new findings; the interim dartdoc-only edit (F3 fix) was
  independently confirmed behavior-identical.
- Standards reverification: **verdict improved to PASS (0 open findings)** —
  F2/F3 verified fixed in the files; F1 verified addressed (commit e7ae9029
  confirmed free of the .gitignore delta; delivery-time staging discipline
  pinned by the contract).
- Security: SF4 was fixed by the same test change Spec reverified (M4);
  SF1/SF2 are accepted-risk records, not correction items — no reverification
  cycle required.

## Supervisor cross-checks of reviewer claims

- Spec's citation of a repo-shipped migration was verified first-hand:
  finalAssignmentBackend/src/main/resources/db/refresh_tokens_alter_token_text.sql
  contains exactly the ALTER used in the EII-2 environment repair (BCrypt →
  ML-KEM envelope ~2KB rationale in file comments). This upgraded the EII-2
  classification evidence.
- During the earlier audit phase, one auditor citation error (401-replay
  logic attributed to interceptor.dart) was corrected by Supervisor
  first-hand reading (actual location: api_client.dart:214-239) — recorded
  as worker-reliability evidence; the substantive claim was correct.
