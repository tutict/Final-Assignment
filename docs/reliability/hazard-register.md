# Hazard register
sys_backup_restore was only a record. Shared backup script writes SUCCESS only after the dump and checksum exist.
Spring Kafka producer retries were 2147483647. They are now capped at 3 with a 10 second delivery timeout.
CDC search indexing can fail after logging. Payment HTTP success no longer depends on Kafka or the search index.
Dev token blacklist fail-open is now false. Redis outage fails closed for revocation checks.
Pool saturation sheds non-ledger GETs with 503 and Retry-After 1. Ledger writes shed only when no connection is free.
AI queue wait default is 1 second. Go model dial and response-header timeouts are 700ms. Ledger threads are not the AI executor.
Payment governance stays shadow. Do not auto-reject stale payment writes.
Go health is exposed at /actuator/health and /api/actuator/health and pings MySQL. Go payment idempotency uses sys_request_history.
Cloud gateway business routes time out at 3 seconds, AI and RAG at 8 seconds, with no gateway retries. CORS is an explicit origin list.
Cloud login rate limit uses the direct remote address, not client X-Forwarded-For.
Nacos remains a known lab single point and is not a new reliability dependency. Quarkus logout, refresh, and blacklist already exist.
Go driver offense and deduction lists return 200 instead of 404. GET /api/system/logs/overview is a static route and returned 200 on 2026-09-26 after the Go process restart.
Login shedding is unified on Spring, Go, the Cloud gateway, and Quarkus: 8 per account per minute, 40 per direct remote IP per minute, then a 2 minute lock. Client X-Forwarded-For is ignored. A probe on 2026-09-26 got 429 with Retry-After 120 on the 9th attempt for Go, the gateway, and Quarkus.
Quarkus Redis caches were typed as one entity while list methods stored JSON arrays. The next read threw DecodeException, aggregateRoles turned that into an empty role set, and the second login returned 401. List methods no longer use @CacheResult. Single-row caches stay.
Cloud Elasticsearch repositories created indexes at startup and exited when 9200 was down. createIndex is now false, and connection failures on repository calls return an empty result so MySQL fallback can run.
This host's Redis 5 answers commands but fails Spring Data Redis INFO parsing, so management.health.redis stays off in local-dev. That does not mean Redis is unused.
Cloud auth login resolves the linked driver through traffic /api/drivers/internal/linked. Traffic now accepts the internal service token, the same way user and audit already did. Gateway login for ce@ce.com returned driverId 6 on 2026-09-26.
Spring and Cloud wrapped a ledger pool timeout as CannotCreateTransactionException, so the generic handler returned 500 without Retry-After. The cause chain now returns 503 with Retry-After 1. Hikari's floor remains 250ms. Go bounds the borrow before BEGIN instead of cancelling the whole transaction at 200ms.
