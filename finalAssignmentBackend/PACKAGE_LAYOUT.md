# Backend Package Layout

This module keeps framework layers grouped by business ownership instead of
flat `controller`, `service`, `entity`, and `mapper` packages.

## Controllers

- `controller.auth`: login, registration, token, and authentication APIs.
- `controller.admin`: user, role, permission, settings, and backup APIs.
- `controller.business`: traffic violation, appeal, driver, vehicle, fine,
  deduction, payment, progress, and workflow APIs.
- `controller.audit`: operation log, login log, and system log APIs.
- `controller.rag`: RAG knowledge and retrieval management APIs.
- `controller.ai`: AI chat-facing APIs.
- `controller.view`: read-only composed view APIs.

## Services

- `service.auth`: token lifecycle and authentication support.
- `service.admin`: admin system data and configuration services.
- `service.appeal`: appeal records and reviews.
- `service.driver`: driver profiles, vehicles, and driver-vehicle relations.
- `service.offense`: offense records, offense types, deductions, and fines.
- `service.payment`: payment records.
- `service.audit`: audit log services.
- `service.ai`: AI chat/search services.
- `service.messaging`: Kafka and business push adapters.
- `service.system`: generic system request/history services.

## Persistence

- `entity.*` and `mapper.*` mirror the same domain groups:
  `admin`, `appeal`, `audit`, `auth`, `driver`, `offense`, `payment`, and
  `system`.
- Elasticsearch documents remain in `entity.elastic` because they are search
  projections rather than MySQL entities.

## Role Naming

- Application role names use canonical values such as `ADMIN`, `SUPER_ADMIN`,
  and `USER`.
- Spring Security authority prefixes are handled at the boundary by
  `SecurityRoleUtils`; business code should not hard-code prefixed admin
  authorities.
