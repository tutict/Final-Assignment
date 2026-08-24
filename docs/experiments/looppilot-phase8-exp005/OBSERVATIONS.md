# EXP-005 Observations

Behavioral notes beyond the scored items; all `observed` unless labeled.

## What the second project stressed that MMGH never did

1. **Red baseline forensics.** MMGH experiments began from green baselines.
   Final-Assignment's `mvn test` failed 76/87 on untouched main. The
   protocol's evidence-honesty rules coped, but nothing in the frozen load
   profiles says what to DO: EXP-005 improvised a two-baseline record
   (as-found vs corrected-environment) and an incident-driven environment
   repair backed by the repo's own shipped migration file. This improvisation
   is the round's strongest candidate for future protocol guidance.
2. **Diagnosis revision under classification discipline.** The baseline
   root cause was revised twice (guard design → schema-drift trigger +
   guard amplifier) as evidence deepened. The Execution-Incident boundary
   kept both wrong intermediate diagnoses from ever becoming Product
   Findings, and the final classification is backed by
   db/refresh_tokens_alter_token_text.sql — the repo knew; the local
   environment didn't.
3. **Worker-report fabrication as the dominant delegation failure mode.**
   MMGH's delegation failures were infrastructure (429/no-output). Here all
   10 delegations returned output, but two preliminary audit summaries
   asserted mitigations that do not exist (an appeal "domain-fingerprint
   dedup"; "user-scoped, 24h TTL" request history; "cross-user 403 tests")
   and one misattributed a code citation. Deep passes with mandatory
   file:line citations, plus Supervisor spot-verification of every
   load-bearing claim, caught all three. Lesson: verification effort should
   concentrate on claims of SAFETY ("already mitigated/tested") — those were
   the fabricated ones; claims of DEFECT came with checkable citations.
4. **A candidate-selection reversal driven by audit depth.** Candidate B
   moved from "rejected: mitigated" to "rejected: too wide to fix honestly
   in one bounded change" — same verdict, opposite reason, materially
   different future roadmap (B is now a top-priority Full-Loop-shaped
   candidate alongside D).

## Protocol behaviors that transferred cleanly

- Mode Selection Gate before implementation felt natural on the second
  stack; the 16 dimensions mapped without edits.
- RED→GREEN with public-API-only tests gave unambiguous defect evidence
  (4 observed failures) without any manufactured breakage.
- Independent review under Lightweight (a first — EXP-002 used self-review)
  was affordable via parallel delegation and produced findings the
  implementer demonstrably would not have written down (SF1/SF2 accepted
  risks; the contract-text overstatement M5).
- Reviewer reverification by the ORIGINAL reviewers closed the loop cheaply
  (one message each; Standards improved to PASS).

## Friction points

- The specialist-trigger escalation literalism (RESULTS H2 tension 1) had
  to be resolved by instruction-priority reasoning (current user instruction
  over frozen doc text) — a future reader without that instruction would
  have faced a genuine contradiction.
- Surefire include drift silently excludes ~34 unit-test classes including
  two security-relevant ones (C-G2) — a repository process finding recorded
  for the owner, out of EXP-005 scope.
- The corrected-environment full suite still fails ~54 tests from the login
  guard's per-IP budget vs the suite's per-test logins. Any future
  Final-Assignment experiment that needs suite-green must first resolve that
  interplay (test-profile guard overrides or shared-token test design) — a
  scoped, well-understood piece of future work.

## Inferred / unmeasured

- Inferred: Full Loop on this change would have added ≥2× artifact count for
  no additional control evidence (based on MMGH EXP-001's recorded cost and
  this change's single-owner shape). Not measured — no A/B this round.
- Unmeasured: token cost (unavailable), wall-clock per phase (not
  instrumented), long-term maintainability of the classification seam.
