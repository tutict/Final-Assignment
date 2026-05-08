# Incremental Legacy Governance Template

Status: accepted

## Context

The Appeal module now has several stable seams: workflow orchestration, event intent classification, after-commit side effects, cache eviction policy, query projection, read intent separation, and idempotency checks. These seams were added without changing API paths, database schema, Kafka topics or payloads, Elasticsearch mapping, or frontend behavior.

## Decision

Use an additive, seam-first governance template for future legacy modules.

The template defines vocabulary for:

- semantic mutation classification
- mutation side-effect policy
- after-commit side-effect coordination
- read/write model boundaries
- projection assembly
- retrieval-safe views

The template deliberately does not define repositories, workflows, event buses, annotations, runtime scanning, generic persistence, or module-wide inheritance.

## Rationale

Full CQRS is not needed because external contracts still return legacy entity-shaped responses, and the existing database remains the system of record.

Event Sourcing is not needed because legacy rows are already authoritative and there is no event log contract to preserve.

Saga or workflow engines are not needed because current orchestration is local and explicit.

Additive seams are preferred because they are rollbackable, compatibility-preserving, and can be adopted module by module.

## Adoption Rules

- Start with explicit module-local policy before extracting shared vocabulary.
- Keep classifiers pure and deterministic.
- Keep side effects after commit when they observe committed state.
- Keep read-side projections separate from write mutation paths.
- Keep retrieval fields whitelisted rather than blacklist-based.
- Promote only vocabulary, not a framework.

## Non-Goals

- No API migration.
- No schema migration.
- No Kafka payload or topic migration.
- No generic repository abstraction.
- No annotation-driven framework.
- No automatic module scanning.
