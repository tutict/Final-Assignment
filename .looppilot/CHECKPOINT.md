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
- Fixed product base: `ba3b49d83e1f73aeab8392fd5a5292d6961b058e`.
- Failed-run preservation commit:
  `b575d143112e9a946a5f1450e2083b29fa2c84ac`, authorized and pushed.
- Reviewed metadata HEAD before the post-review correction:
  `a4f36d463d5429f3a7cbefffaf1766df697524db`.
- The final metadata correction is the commit containing this Checkpoint; its
  exact SHA is verified against the remote and reported after commit because a
  commit cannot contain its own SHA.
- Preservation commits do not authorize product integration or acceptance.
- The preserved partial Flutter tests include a modeled response-read-loss
  scenario, but they have no Delivery and were not independently reviewed,
  executed, or accepted. They provide no acceptance evidence and make no live
  transport-loss claim.

## Resume Point

On resume, report the blocked Project/Loop and request a new explicit instruction
before altering, discarding, integrating, committing, or pushing the preserved
partial edits.
