# EXP-006 Full Loop Project

## Authority

This file is the sole authority for Project scope and status. The Supervisor
decides scope and acceptance; the Integrator records authorized transitions.

## Status

Blocked.

The fixed outcome was not delivered. Mandatory backend TASK-002 and frontend
TASK-003 ended blocked with unattributed, unreviewed partial edits; TASK-004 could
not start. This status does not authorize further work, commit, push, release, or
deployment.

## Objective

Make authenticated `POST /api/appeals` and its Flutter caller safe for duplicate
delivery and response-read retry by binding one operation key to one durable
appeal result.

## Scope

- Spring appeal creation idempotency, history reservation, transaction boundary,
  duplicate response, and focused tests.
- Flutter appeal creation operation/key lifecycle, retry behavior, HTTP 208
  nullable-data handling, and focused tests.
- Cross-layer evidence that one Flutter key reaches the Spring header and request
  history, retries reuse it, and duplicate delivery leaves one appeal row.
- Public-safe Full Loop evidence and the Full Loop Arm run report.

## Excluded

- `main`, schema or migration changes, dependency changes, authentication design,
  unrelated backend or React code, release, deployment, PRs, merges, and tags.
- Live TCP response-loss claims unless directly observed. Response loss may be
  modeled and must be labelled modeled.

## Fixed Acceptance

Spring: S-1 through S-8 exactly as supplied by the user. Flutter: F-1 through
F-9 exactly as supplied by the user. Cross-layer fixture: Flutter key = Spring
header = request history = retry, with one matching appeal row.

## Delivery Boundary

Local implementation, verification, authorized commit, and push to
`experiment/looppilot-final-assignment-exp-006-full-loop` are permitted. Project
delivery does not authorize release or deployment.
