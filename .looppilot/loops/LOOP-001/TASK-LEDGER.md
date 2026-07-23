# TASK-LEDGER

## Authority

This file is the sole authority for LOOP-001 Task status. Only the Integrator may
record transitions.

| Task | Depends on | Status |
|---|---|---|
| TASK-001 | none | Integrated |
| TASK-002 | TASK-001 | Blocked (partial; EII-004/EII-006/EII-008) |
| TASK-003 | TASK-001 | Blocked (partial; EII-005/EII-007/EII-009) |
| TASK-004 | TASK-002, TASK-003 | Blocked (dependencies incomplete) |

`Approved` means review passed. `Integrated` means the approved delivery was
combined and passed integration checks; neither means Loop acceptance.
