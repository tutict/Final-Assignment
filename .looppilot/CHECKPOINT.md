# Recovery Checkpoint

## Authority

This file is the sole recovery authority. It conveys no commit, push, release, or
deployment permission.

## Observed State

- Branch: `experiment/looppilot-final-assignment-exp-006-full-loop`.
- Fixed base/HEAD at Contract Barrier: `ba3b49d83e1f73aeab8392fd5a5292d6961b058e`.
- Worktree was clean before Full Loop artifacts were created.
- PROJECT status is Blocked; LOOP-001 status is Blocked.
- Contract Barrier artifacts define one Loop and four-task DAG.
- TASK-001 delivery is independently Spec/Standards reviewed and Integrated.
- TASK-002 is blocked/partial after EII-004/EII-006/EII-008; no further backend
  implementation assignment is authorized in this run.
- TASK-003 is blocked/partial after EII-005/EII-007/EII-009; its frontend
  edits/tests remain unreviewed and unintegrated.
- TASK-004 did not start because TASK-002 and TASK-003 are incomplete.
- The fixed product base remains `ba3b49d83e1f73aeab8392fd5a5292d6961b058e`;
  preservation commit `b575d143112e9a946a5f1450e2083b29fa2c84ac` contains the
  blocked-run artifacts and partial edits, with no uncommitted changes after its
  push.
- Failed-run preservation commit `b575d143112e9a946a5f1450e2083b29fa2c84ac` was
  authorized and pushed; it preserves the blocked boundary and does not authorize
  product integration or acceptance.

## Resume Point

On resume, report the blocked Project/Loop and request a new explicit instruction
before altering, discarding, integrating, committing, or pushing the preserved
partial edits.
