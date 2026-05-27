# Backend Package Layout

The Spring Boot backend is organized by business ownership first, then by framework layer. The goal is to keep traffic-domain code, admin code, audit code, AI/RAG code, and shared infrastructure clearly separated.

## Controllers

- `controller.auth`: login, registration, token, and authentication APIs.
- `controller.admin`: user, role, permission, settings, backup, and admin-facing configuration APIs.
- `controller.business`: traffic violation, appeal, driver, vehicle, fine, deduction, payment, progress, and workflow APIs.
- `controller.audit`: operation log, login log, and system log APIs.
- `controller.rag`: RAG knowledge ingestion, upload, indexing, and retrieval management APIs.
- `controller.ai`: AI chat-facing APIs.
- `controller.view`: read-only composed view APIs.

## Services

- `service.auth`: token lifecycle and authentication support.
- `service.admin`: admin system data, settings, backup, users, roles, and permissions.
- `service.appeal`: appeal records and reviews.
- `service.driver`: driver profiles, vehicles, and driver-vehicle relations.
- `service.offense`: offense records, offense types, deductions, and fines.
- `service.payment`: payment records.
- `service.audit`: login and operation audit logs.
- `service.ai`: AI chat/search service adapters.
- `service.messaging`: Kafka and business push adapters.
- `service.system`: generic request history and system support services.

## AI And RAG

- `ai.chat`: chat orchestration and provider integration.
- `ai.rag`: query-time retrieval, ACL filtering, reranking, prompt context, and embedding search.
- `rag.config`: RAG indexing configuration.
- `rag.ingestion`: database source extraction and uploaded file parsing.
- `rag.chunk`: text chunking.
- `rag.indexing`: backfill jobs and indexing orchestration.
- `rag.service`: document, chunk, and embedding task persistence.
- `rag.entity` / `rag.mapper`: MySQL tables backing RAG documents and chunks.

Supported upload parsing currently includes `txt`, `md`, `csv`, `tsv`, `json`, `docx`, `xlsx`, and text-based `pdf`.

## Persistence

- `entity.*` and `mapper.*` mirror the same domain groups:
  `admin`, `appeal`, `audit`, `auth`, `driver`, `offense`, `payment`, and `system`.
- Elasticsearch documents stay in `entity.elastic` because they are search projections rather than MySQL entities.
- RAG persistence uses `rag.entity` and `rag.mapper` because it belongs to the AI knowledge subsystem.

## Configuration

- `config.security`: JWT, authorization, CORS, and role-boundary security.
- `config.db`: database-facing bootstrap and schema maintenance, including sensitive-data backfill.
- `config.shell`: local environment startup integration.
- `config.ai` / `ai.*`: AI provider and retrieval-related configuration.
- `config.kafka` or Kafka listener packages: topic listeners and message infrastructure.

## Shared Infrastructure

- `common.idempotency`: shared idempotent request and Kafka message execution helpers.
- `security`: role utilities and authentication boundary helpers.
- `cdc`: MySQL CDC to Elasticsearch synchronization.
- `elasticsearch`: search index and document conversion support.

Kafka Listener code should use `IdempotentKafkaMessageProcessor` unless the listener has a domain-specific reason to customize duplicate handling. Complex listeners such as offense and payment records may still run domain governance logic before delegating success/failure handling.

## Role Naming

- Application role names use canonical values such as `ADMIN`, `SUPER_ADMIN`, and `USER`.
- `ADMIN` is the normal business administrator role.
- `SUPER_ADMIN` is for technical administration: operation log review, RAG management, and high-risk system operations.
- Spring Security authority prefixes are handled at the boundary by `SecurityRoleUtils`; business code should not hard-code prefixed admin authorities.

## Sensitive Data Rule

Sensitive fields should not be queried by plaintext once a blind-index field exists. New code should prefer:

1. persist plaintext for compatibility only when required by the existing schema,
2. write `*_ciphertext` through the sensitive-data persistence service,
3. write `*_blind_index` for exact lookup,
4. expose masked values to Elasticsearch or external clients.
