# Experiment SLO
Lab contract for host MySQL traffic plus the compose dependencies. Not a multi-zone promise.
Targets: ledger checks at least 0.99, unexpected failures under 1 percent, p95 at most 200ms, p99 at most 500ms, on a 5 minute k6 run near 16 VUs.
Login 429 and pool 503 with Retry-After 1 are not failures. A 5xx without Retry-After, or silence for 3 seconds, is a failure.
AI unreachable model returns 200 with isFallback true within 1 second. Spring and Cloud fall back to MySQL if Elasticsearch is down.
RPO 15 minutes via scripts/reliability/backup-traffic.ps1. RTO 30 minutes into traffic_restore_drill. Never replace live traffic.
Checksum payment_record, fine_record, deduction_record, appeal_record: row count, max id, amount or points.
Missing Idempotency-Key on ledger POST is 400. Same key and body replays, payment replay stays 208. Different body is 409. In progress is 409 with Retry-After 1.
Before, 2026-09-21, 20 seconds: Spring checks 1.000 p95 56ms; Cloud 1.000 p95 97ms; Quarkus 1.000 p95 101ms; Go 0.571 p95 3.6ms and fails. Source docs/performance/load-test-2026-09-21.md. Do not loosen targets. Fresh 5 minute run still required.
Flags read at startup: RELIABILITY_LOAD_SHED true, RELIABILITY_BACKUP_SCHEDULER false and not installed, TOKEN_BLACKLIST_FAIL_OPEN false.

## After: Spring only, 2026-09-26, 5 minutes
Backend http://127.0.0.1:9080. Redis was a local redis-server on 6379. Kafka and Elasticsearch were down because Docker Desktop cannot start. k6: PERF_DURATION=5m, user 8, admin 6, super 2. Summary artifacts/k6/spring-after-5m.log.
requests=29961. http_req_failed_rate=0.019. checks_rate=0.974. avg=76ms. p95=287ms. p99=394ms.
health_ok=1.000. user_read_ok=0.999. admin_read_ok=0.999. super_read_ok=0.839. login_ok=0.306.
Gap, targets not loosened: p95 is above 200ms. Aggregate checks are below 0.99. login_ok is low because the 1/s login scenario hits the 8/minute account limit and those 429 responses are explicit shedding, not ledger failures. super_read includes RAG preview, which needs Elasticsearch and was down. Go, Quarkus, and Cloud were not measured in this run.
Hikari refuses connectionTimeout below 250ms, so the pool acquire timeout default is 250ms rather than 200ms. Ledger posts still return 503 when the pool has no idle connection.

## After: Go, 2026-09-26, 5 minutes
Backend http://127.0.0.1:18080, binary artifacts/go-backend-next.exe. Same profile as Spring: PERF_DURATION=5m, user 8, admin 6, super 2, login 1/s, include_ai=false. Redis up. Kafka and Elasticsearch down. Summary artifacts/k6/go-after-routes-5m.log and artifacts/k6/go-after-routes-5m.json.
requests=61996. http_req_failed_rate=0.0016 (101 requests). checks_rate=0.993. avg=2.8ms. p95=4.2ms. p99=10.8ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=0.900. login_ok=0.664 (200 passes, 101 fails).
The previous Go run had user_read_ok=0.750 because GET /api/offenses/driver/:id and GET /api/deductions/driver/:id were missing and returned 404. Both now return 200 and an empty list when the driver has no rows. Ledger reads in this run had no check failures.
All 101 HTTP failures are login 429 from the Go limiter: 40 requests per IP per minute, Retry-After 60. That is login shedding, not a ledger error. Excluding those 429s, unexpected failures are 0. k6 still counts them in http_req_failed and login_ok because the script threshold expects login 200.
Gap, targets not loosened: super_read_ok stays 0.900. GET /api/system/logs/overview is captured by /:logId and returns 404 log not found. Direct checks of the other super routes, including RAG preview, returned 200. This route is outside the Go ledger subset (health, login, offenses, fines, payments, appeals). Go does not yet apply Spring's extra 8 per account per minute limit or the 2 minute lock; the Cloud gateway limiter is the same 40 per IP rule.

## After: Quarkus, 2026-09-26, 5 minutes
Backend http://127.0.0.1:19080, quarkusDev. Spring already owned 8080 and 9080, so this run used QUARKUS_HTTP_PORT=19080. Same k6 profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Redis up. Kafka and Elasticsearch down; Kafka consumers logged connection failures and did not fail the ledger reads. Summary artifacts/k6/quarkus-after-5m.log and artifacts/k6/quarkus-after-5m.json.
requests=50933. http_req_failed_rate=0. checks_rate=1.000. avg=14.9ms. p95=53.8ms. p99=108.5ms. max=398ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000 (300/300).
Before the run, a cold login succeeded and the next login returned 401 "No roles assigned to user." Redis caches are typed as one entity, but list methods stored JSON arrays. The following read threw DecodeException, aggregateRoles swallowed it as an empty role set. List-returning @CacheResult methods now hit MySQL. Single-row caches remain. The measured run was after that change and after FLUSHDB of the poisoned cache keys.
Gap, targets not loosened: this is dev mode, not a packaged jar. Login did not shed at 1/s, so Quarkus still does not apply the 8 per account per minute limit or the 40 per IP limit. Cloud was not measured in this run.

## After: Cloud, 2026-09-26, 5 minutes
Gateway http://127.0.0.1:18090. Static discovery, Nacos off. Same k6 profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Redis up. Kafka and Elasticsearch down. Summary artifacts/k6/cloud-after-5m.log and artifacts/k6/cloud-after-5m.json.
requests=25076. http_req_failed_rate=0.0045 (113 requests). checks_rate=0.992. avg=18.8ms. p95=54.0ms. p99=250.8ms. max=651ms.
health_ok=1.000. user_read_ok=0.9997 (3 misses). admin_read_ok=0.998 (8 misses). super_read_ok=1.000. login_ok=0.661 (199 passes, 102 fails).
The 102 login failures match the gateway limiter of 40 per IP per minute with Retry-After 60. Those are login shedding. Excluding them, unexpected failures are about 11 requests, under 0.1 percent. p95 and checks meet the experiment SLO. p99 is inside 500ms.
Cloud login for ce@ce.com returned driverId null because the auth service's Feign call to /api/drivers/internal/linked got a 4xx. The user scenario therefore skipped driver-scoped offense, fine, payment, and deduction reads. Admin reads still covered those lists.
Startup gap that was fixed before this run: user, traffic, and the other services called Elasticsearch index creation during repository construction and exited when port 9200 refused the connection. Documents now set createIndex false, and an aspect turns a later connection failure into an empty search result so the existing MySQL fallback can run. Aggregate /actuator/health was 503 on this Redis 5 build because INFO cannot be parsed; local-dev now leaves the Redis health indicator off by default so readiness means the process is serving. Redis itself stayed up.
Separate probes, not part of the 5 minute rates: a driver token gets 403 from /api/rag/admin/documents on Spring, Go, and Quarkus. Quarkus logout makes the same token receive 401 on /api/auth/me and on POST /api/payments.

## Redis stopped, 2026-09-26
Redis 5 on 127.0.0.1:6379 was stopped and started again. PING returned PONG after the restart. An admin token was taken while Redis was up.
Spring 9080, Quarkus 19080, and Cloud gateway 18090: login 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT; GET /api/auth/me with the old token stayed 200; POST /api/payments with Idempotency-Key returned 503 with Retry-After 1. No second payment was inserted by that shed.
Go 18080: the same GET stayed 200. curl showed login and the payment POST both return 503, Retry-After 1, body {"errorCode":"DEPENDENCY_TIMEOUT"}. A parallel Python client reported connection reset for those two Go calls; the curl headers are the status that was actually written.

## Kafka down, payment, 2026-09-26
Kafka port 9092 was not listening. Before the fix, a Spring payment committed in MySQL and then the HTTP client timed out at 8 seconds because the after-commit Kafka send blocked the request thread. Replay of that key returned 208 and did not insert a second row.
The listener now publishes on another thread, and the producer max.block.ms is 500. After restarting Spring on 9080, a new payment returned 201 in 140ms. The same key replayed as 208 in 30ms. payment_record went from 5 rows and 801.00 to 6 rows and 802.00. sys_request_history for that key is SUCCESS with business_id 6. kafka_publish_failed_total is 1.
Spring startup no longer creates Elasticsearch indexes, so a down search port does not stop the process. This process was started with the Docker and Ollama bootstrap scripts off and the AI draft store in memory.
## Probes after the 5 minute runs, 2026-09-26
These are single-request checks, not a new 5 minute k6. Targets above are unchanged.
Go 18080 was rebuilt as artifacts/go-backend-redis-next.exe. The 9th login for one account returned 429, Retry-After 120, errorCode LOGIN_RATE_LIMITED. A different account from the same IP still reached the credential check. GET /api/system/logs/overview with a superadmin token returned 200. Redis commands use MaxRetries -1 so a timeout is not retried 3 times.
Cloud gateway 18090 and traffic 18083 were repackaged and restarted with Nacos config import disabled. ce@ce.com login through the gateway returned 200 and driverId 6. The 9th gateway login for one unused account returned 429, Retry-After 120. The old 5 minute gap (driverId null, 40/IP only) is not remeasured here.
Quarkus 19080 was restarted in quarkusDev after a hot-reload compiler failure. The 9th login for one account returned 429, Retry-After 120. A known user login still returned 200. Kafka 9092 is still down; consumers log disconnects and do not decide payment success.
Spring 9080 is not in this probe. The earlier process had exited because the datasource URL was not set. Docker Desktop was started again after renaming the stuck Inference socket directory, but these probes still use the local MySQL and Redis.
Spring 9080 was started again with the local datasource and Docker/Ollama bootstrap scripts off. With the Ollama process stopped, GET /api/ai/chat/actions?message=zzzz-reliability-probe&webSearch=false returned 200 and isFallback true in 1063ms. That is still over the 1 second gate, so the target is not loosened. Ollama was started again and port 11434 was listening.
After the chat action timeout was cut to 700ms and Spring devtools restarted, the same Ollama-down probe returned 200 with isFallback true in 781ms. That meets the 1 second gate. Ollama was started again. Elasticsearch repository failures now open a 15 second circuit and skip further calls until the next probe, so a down search port does not add an 800ms wait to every ledger read. A new 5 minute Spring k6 is the check for the earlier p95 of 287ms.

## After: Spring, 2026-09-26, second 5 minutes
Backend http://127.0.0.1:9080 after the 700ms AI cap and the Elasticsearch 15s circuit. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/spring-after-ai-5m.log and artifacts/k6/spring-after-ai-5m.json.
requests=51221. http_req_failed_rate=0.012. checks_rate=0.984. avg=15.2ms. p95=35.2ms. p99=63.3ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=0.818. login_ok=0.309 (93 passes, 208 fails).
Latency now meets p95 200ms and p99 500ms. The earlier p95 of 287ms is not the current run. Targets are not loosened.
Gaps that remain: checks 0.984 is below 0.99, and http_req_failed 1.2 percent is above 1 percent. login_ok counts only HTTP 200 because the k6 Retry-After lookup was case-sensitive, so explicit 429 shedding was marked failed. That lookup now also reads retry-after. super_read_ok 0.818 is a separate miss; a single call of the same super routes after the run returned 200. This run does not replace the Go, Quarkus, or Cloud 5 minute results above.

## After: Spring, 2026-09-26, Redis connection fix, 5 minutes
Backend http://127.0.0.1:9080. Lettuce no longer opens a dedicated connection per command. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/spring-after-redis-5m.log and artifacts/k6/spring-after-redis-5m.json.
requests=58816. http_req_failed_rate=0. checks_rate=1.000. avg=5.3ms. p95=7.5ms. p99=12.9ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
The previous 1.2 percent failure rate was Redis connection churn: shareNativeConnection was false, so each command dialed a new socket and failed with BindException Address already in use. Login then returned 503 even though Redis was up. That is fixed. Login 429 with Retry-After still counts as shedding. Targets were not loosened. Go, Quarkus, and Cloud still need a fresh 5 minute run after their own changes.

## After: Go, 2026-09-26, contract routes, 5 minutes
Backend http://127.0.0.1:18080, binary artifacts/go-backend-redis-next.exe. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/go-after-contract-5m.log and artifacts/k6/go-after-contract-5m.json.
requests=62363. http_req_failed_rate=0. checks_rate=1.000. avg=1.9ms. p95=2.8ms. p99=3.8ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
The earlier super_read 0.900 was GET /api/system/logs/overview hitting /:logId. That route now returns 200. Login 429 with Retry-After is counted as shedding, so login_ok is 1.000 instead of 0.664. Targets were not loosened.

## After: Quarkus, 2026-09-26, login limit, 5 minutes
Backend http://127.0.0.1:19080, quarkusDev. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/quarkus-after-limit-5m.log and artifacts/k6/quarkus-after-limit-5m.json.
requests=51813. http_req_failed_rate=0. checks_rate=1.000. avg=12.5ms. p95=45.5ms. p99=76.6ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
The 8 per account and 40 per IP limits are now present. Login 429 with Retry-After counts as shedding, so the run stays at login_ok 1.000. This is still dev mode, not a packaged jar. Targets were not loosened.

## After: Cloud, 2026-09-26, static discovery restored, 5 minutes
Gateway http://127.0.0.1:18090. Traffic was restarted with config/local-dev.yml so Feign can find the user service. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/cloud-after-discovery-5m.log and artifacts/k6/cloud-after-discovery-5m.json.
requests=55158. http_req_failed_rate=0.00031. checks_rate=0.9997. avg=10.2ms. p95=27.0ms. p99=47.6ms.
health_ok=1.000. user_read_ok=0.9997. admin_read_ok=0.9994. super_read_ok=1.000. login_ok=1.000.
An earlier run the same evening, artifacts/k6/cloud-after-driver-5m.json, had user_read_ok 0.125 and http_req_failed 0.666 because traffic had been restarted without the static discovery file. Driver-scoped reads then failed closed with User not found. That run is not the acceptance result. Targets were not loosened.

## Overload shed, 2026-09-26
Spring was started with Hikari maximum pool size 2 and minimum idle 1. Forty concurrent GET /api/auth/me calls returned 19 responses of 503 with Retry-After 1 and 21 responses of 200. That is the non-ledger GET shed when the pool is full. The normal pool of 32 was restored afterward; liveness is 200.
A payment with a new Idempotency-Key returned 201 and created payment_id 7. The same key and body returned 208. payment_record went from 6 rows and 802.00 to 7 rows and 803.00, so the replay did not insert a second payment. The pool was then restored to maximum 32 and minimum idle 8.

## Cloud payment idempotency, 2026-09-26
Cloud traffic no longer marks a payment history SUCCESS before the row is inserted, and a Kafka send failure is no longer allowed to fail that insert. LedgerIdempotencyDeciderTest covers a new key, same body replay, different body conflict, FAILED retry, and PROCESSING before and after two minutes. Tests run: 5, failures: 0.
Through the gateway, POST /api/payments without Idempotency-Key returned 400. A new key returned 201. The same key and body returned 208. The same key with a different amount returned 409. payment_record went from 7 rows and 803.00 to 8 rows and 804.00.

## Quarkus payment idempotency, 2026-09-26
Quarkus LedgerIdempotencyDeciderTest ran 5 tests with 0 failures: new key, same body replay, different body conflict, FAILED retry, and PROCESSING before and after two minutes. The history lookup now aliases snake_case columns, so a SUCCESS row is not read back with an empty status and mistaken for a conflict. Through http://127.0.0.1:19080, a missing Idempotency-Key returned 400, a new key returned 201, the same key and body returned 208, and the same key with a different amount returned 409. payment_record went from 10 rows and 806.00 to 11 rows and 807.00.

## AI bulkhead, 2026-09-26
Each process now keeps at most 2 model calls in flight. A third call does not wait: it degrades immediately and does not touch the provider.
Spring: ModelCallBulkheadTest, ChatAgentTest, and AiChatControllerStreamingTest together ran 13 tests, 0 failures. The full-gate cases assert isFallback and that the provider is not called.
Go: TestModelBulkheadRejectsThirdInFlight and TestAiChatHandler_StreamChatBulkheadFull passed. The HTTP response is 200 and contains isFallback true.
Quarkus: ModelCallBulkheadTest passed, and quarkusDev on 19080 was restarted with GraalVM 23 after a hot-reload compiler error. /q/health/live and /actuator/health both returned 200.
Cloud AI module compiled, including the same gate on chat actions and streams. The running Spring 9080 and Go 18080 processes were not restarted, so they do not have this gate yet.

## Overload shed script, 2026-09-26
Spring http://127.0.0.1:9080. k6 scripts/k6/ledger-shed.js, 40 constant VUs, 15s. Summary artifacts/k6/ledger-shed-spring.json.
iterations=18414. http_reqs=55243. checks=73656/73656 (rate 1.000). shed_503 count=646. The counter increments only for HTTP 503 with Retry-After 1. The check that a 503 carries Retry-After 1 did not fail.
http_req_failed rate=0.0117 is those 646 shed responses. The contract counts them as discards, not unexpected failures. Targets were not loosened.
The replay check forbids a second 201 for the same key and body. It passed on every iteration. MySQL confirmed no duplicate payment_number among the rows this run inserted. Those pending rows were removed after the proof so traffic is back to 13 payment rows and 809.00. fine_id 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00.


## Backup drill and Quarkus auth, 2026-09-26
scripts/reliability/backup-traffic.ps1 exited 0. Manifest artifacts/backups/traffic-20260926-234458.manifest.txt. git=532fdfb4593fc5c2983251761e7f80b11503a0fa. binlog=FHNUM2-bin.000768 at 59867679.
Checksum: payment_record 13 rows, max 13, sum 809.00; fine_record 4, max 4, sum 800.00; deduction_record 0; appeal_record 1 row, max 1.
scripts/reliability/restore-traffic-scratch.ps1 exited 0 into traffic_restore_drill. Restored checksum matched. Live payment_record stayed 13. The dump, checksum, and manifest ACLs are only FHNUM2\tutic read/write. The script now fails if icacls cannot remove inherited access.
Driver ce@ce.com on Quarkus 19080 and Spring 9080: GET /api/rag/admin/overview returned 403. Quarkus admin payment with a live token returned 201, logout returned 200, and the same token then returned 401 Token has expired. That probe row was removed; payment_record is again 13 rows and 809.00. fine_id 1 paid_amount stayed 202.00.


## Idempotency live set, 2026-09-26
Same payment body shape on the running processes. A preset FAILED row in sys_request_history was retried with that key.
Spring 9080: mismatched driver returned 400 and marked the key failed; the same key then returned 201, the same body returned 208, and a different amount returned 409 IDEMPOTENCY_CONFLICT. Eight concurrent posts with one key returned one 201 and seven 208s.
Go 18080, Quarkus 19080, and Cloud gateway 18090: the preset FAILED key returned 201, and the immediate replay returned 208. Concurrent posts returned one 201. The other calls were 208 or 409 in progress, not a second 201.
No payment_number was inserted twice. The probe rows were deleted. payment_record is 13 rows, max id 13, sum 809.00. fine_id 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00.

## Process restart, 2026-09-26
Go was rebuilt as artifacts/go-backend-bulkhead.exe and restarted on 18080. /actuator/health returned UP and admin login returned 200. Spring was restarted with artifacts/start-spring-normal.ps1, Hikari maximum 32 and minimum idle 8, TOKEN_BLACKLIST_FAIL_OPEN false. It listened on 9080 and liveness is checked in the same pass. Both processes now include the two-permit AI bulkhead.
The backup script documents a manual 15 minute schtasks example and does not register it.

## Kafka down, 2026-09-27
Kafka 9092 was not listening. Spring payment create still returned 201 in 0.092s. kafka_publish_failed_total moved from 0 to 1 within 3 seconds. The producer config no longer uses unbounded retries. KafkaProducerConfigTest passed: retries 3, delivery.timeout.ms 10000, request.timeout.ms 3000, max.block.ms 500, acks all.
History kafka-fast-1790438726023 was SUCCESS with business_id 18283, and that payment row existed. POST /actuator/ledgerReconcile returned 200 and updated 0, because the history already matched the row. An earlier reconcile of two stale PROCESSING rows with no business id returned updated 2 and left them FAILED.
The probe payments were removed. payment_record is 13 rows, max id 13, sum 809.00. fine_id 1 paid_amount stayed 202.00.

## Ollama down, 2026-09-27
Windows Ollama on 11434 was stopped. GET http://127.0.0.1:11434/api/tags timed out. During that window, GET /api/ai/chat/actions?message=open%20appeal%20page returned 200 in 28.5ms with isFallback true and answer AI 动作生成暂时不可用. Concurrent ledger reads of GET /api/payments?page=1&size=5: 185 responses, all 200, p95 24.6ms, p99 75.5ms. Ollama was started again afterward.

## Redis down, 2026-09-27
Spring 9080, local redis-server on 6379 stopped after a JWT had already been issued. Login returned 503 in 212ms with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. GET /api/payments?page=1&size=1 with that unrevoked token returned 200. POST /api/payments returned 503 in 213ms with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. No payment row was added; payment_record stayed 13 rows and 809.00. Redis was started again and Spring was restarted so login returned 200.

## Elasticsearch down, Spring ledger read, 2026-09-27
Port 9200 was not listening. A direct GET /api/payments?page=1&size=5 still returned the 13 MySQL payment rows. k6 scripts/k6/ledger-read.js for 5 minutes, 16 VUs, admin token, payments fines deductions appeals and offenses. Summary artifacts/k6/spring-es-down-ledger-5m.json.
http_reqs=87361. checks=87360/87360 (rate 1.000). http_req_failed=0. p95=8.91ms. p99=10.79ms. All inside the experiment SLO. Targets were not loosened.

## Elasticsearch down, Cloud ledger read, 2026-09-27
Port 9200 was not listening. Gateway http://127.0.0.1:18090. A direct GET /api/payments?page=1&size=5 returned the 13 MySQL payment rows. k6 scripts/k6/ledger-read.js for 5 minutes, 16 VUs, same ledger paths as Spring. Summary artifacts/k6/cloud-es-down-ledger-5m.json.
http_reqs=80415. checks=80365/80414 (rate 0.9993). http_req_failed=0.0006 (49 requests). p95=32.89ms. p99=59.21ms. Thresholds passed. Targets were not loosened.

## Redis down, four backends, 2026-09-27
Redis on 6379 was stopped after each backend had already issued an admin JWT. Login, GET /api/payments?page=1&size=1, and POST /api/payments were then tried on Spring 9080, Go 18080, Cloud 18090, and Quarkus 19080.
All four logins returned 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. All four GETs with the unrevoked token returned 200. Spring, Cloud, and Quarkus payment posts returned 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. Go's gin log recorded POST /api/payments as 503 in 400.86ms; the Python client reported a connection reset for that same call. No payment row was added. Redis was started again and all four logins returned 200.

## Kafka down, Go Quarkus Cloud, 2026-09-27
Port 9092 was not listening. Payment create returned 201 on Go 18080 in 19.6ms, Cloud gateway 18090 in 35.8ms, and Quarkus 19080 in 34.0ms.
History matched the inserted rows: go-kafka-1790440604223 SUCCESS business_id 18284, cloud-kafka-1790440604223 SUCCESS 18285, quarkus-kafka-1790440604223 SUCCESS 18286. All three payment rows existed and were Pending, so the fine balance did not change.
Go and Quarkus payment creation does not publish to Kafka, so there is no payment publish failure counter to increment. The running Cloud sender logs a Kafka failure and does not increment a metric. Probe rows were deleted. payment_record is 13 rows, max id 13, sum 809.00. fine_id 1 paid_amount stayed 202.00.


## Kafka down, Cloud failure counter, 2026-09-27
Port 9092 was not listening. Cloud traffic was rebuilt and restarted on 18083 with local-dev.yml, Nacos off, and the bounded producer. Gateway http://127.0.0.1:18090 payment create returned 201 in 0.509s. Direct traffic /actuator/prometheus kafka_publish_failed_total moved from 0.0 to 1.0 within 3 seconds. History for that key was SUCCESS with business_id 18287, and the payment row existed as Pending, so the fine balance did not change.
DevKafkaConfigurationTest passed: 1 test. PaymentKafkaPublishTest passed: 3 tests. Producer settings are retries 3, delivery.timeout.ms 10000, request.timeout.ms 3000, max.block.ms 500, acks all, idempotent producer, max in flight 5.
The probe payment and history row were deleted. payment_record is 13 rows, max id 13, sum 809.00. fine_id 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Go and Quarkus still do not publish payment_record_create, so this counter does not apply to those payment creates.


## Go reliability metrics, 2026-09-27
Go /actuator/prometheus now reports load shed, idempotency conflict, dependency timeout, Kafka publish failure, AI fallback, backup time, pool wait, and HTTP result class. A non-admin request is still 403. Unit tests in internal/reliability passed, including the shed policy and a dependency-timeout increment.
The rebuilt process is artifacts/go-backend-bulkhead.exe on 18080. After restart, /actuator/health returned UP. An admin scrape returned backup_last_success_timestamp 1790437499, the same UNIX_TIMESTAMP(MAX(backup_time)) as sys_backup_restore status Success. The other counters were 0 because this scrape did not shed, time out, or conflict. http_responses_2xx_total was 2 from the health check and login that preceded the scrape.


## Quarkus reliability metrics, 2026-09-27
Quarkus /actuator/prometheus no longer returns a fixed zero string. ReliabilityMetricsTest and LoadShedPolicyTest passed: 1 test each, 0 failures. Counters increment for dependency timeout, idempotency conflict, AI bulkhead fallback, Kafka publish failure, and load shed.
The dev process was restarted with GraalVM 23 on 19080 after a hot reload used the wrong javac and returned 500. After restart, /actuator/health returned UP. An admin scrape returned backup_last_success_timestamp 1790437499, matching sys_backup_restore status Success, plus db_pool_awaiting 0 and db_pool_blocking_ms 0. http_responses_2xx_total was 2 from the health check and login. The event counters were 0 because this scrape did not shed, time out, or conflict. An anonymous scrape returned 401.


## Cloud traffic reliability metrics, 2026-09-27
Cloud traffic on 18083 now exposes load_shed_total, idempotency_conflict_total, dependency_timeout_total, kafka_publish_failed_total, backup_last_success_timestamp, db_pool_wait_count, and HTTP result class counters. TrafficReliabilityMetricsTest passed: 2 tests, 0 failures. Idempotency conflicts increment only for a different body, not for an in-progress key. Redis write rejection in the service JWT filter calls dependencyTimeout.
After restart, an admin scrape of /actuator/prometheus returned backup_last_success_timestamp 1790437499, matching sys_backup_restore status Success, and db_pool_wait_count 0. The event counters were 0 because this scrape did not shed, conflict, or time out. http_responses_2xx_total was 1 from the health check.


## Cloud auth dependency timeout metric, 2026-09-27
Auth login, refresh, and authenticated writes now increment dependency_timeout_total when Redis cannot be reached. AuthReliabilityMetricsTest passed: 1 test, 0 failures. The auth process was restarted on 8081. Gateway login returned 200. An admin scrape of http://127.0.0.1:8081/actuator/prometheus showed dependency_timeout_total 0.0 because Redis was up.


## Database wait bounds, 2026-09-27
Hikari rejects a connection timeout below 250ms, so Cloud traffic and the Spring source use 250ms, not 200ms. A ledger write that cannot get a connection is mapped to 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. Other routes stay 500. LedgerConnectionPolicyTest passed for Cloud and Spring, 1 test each.
Cloud traffic was restarted on 18083 and /actuator/health returned 200. The earlier start with 200ms exited because Hikari refused the value. MySQL session max_execution_time is 3000ms on that datasource. Go's built-in DSN now uses timeout=200ms, readTimeout=3s, and writeTimeout=3s. The Go process was restarted on 18080 and /actuator/health returned UP. The running Spring process was not restarted, so its new 503 mapping is in source only.


## Redis command timeouts, 2026-09-27
Cache commands are 300ms and blacklist commands are 200ms. Spring uses separate Lettuce factories. Go cache read/write timeout is 300ms and the blacklist client is 200ms. RedisCommandTimeoutsTest passed: 1 test. Go configs/redis tests passed.
The Go process was restarted on 18080 after local redis-server was started again on 6379. /actuator/health returned UP. The running Spring process was not restarted, so its split timeouts are in source and tests only.


## Cloud traffic Redis timeouts, 2026-09-27
Traffic cache Redis commands use 300ms. The JWT blacklist check uses a separate Lettuce client at 200ms. RedisCommandTimeoutsTest in finalassignmentcloud-common passed: 1 test, 0 failures. Traffic was restarted on 18083 and /actuator/health returned 200. Other Cloud services still use the shared 200ms Redis timeout. The running Spring process was not restarted.


## Gateway health with AI down, 2026-09-27
AI on 8086 was not listening. Gateway http://127.0.0.1:18090/actuator/health returned 200 and {"groups":["liveness","readiness"],"status":"UP"}. It did not include AI component details. Discovery health remains disabled.
Auth had exited, so the first gateway login returned 500 because Feign could not reach finalassignmentcloud-user. User was restarted on 18082 and audit on 8084. The next gateway login returned 200. Quarkus was restarted on 19080 and /actuator/health returned 200.


## Quarkus Redis blacklist timeout, 2026-09-27
Quarkus Redis is the token blacklist, not the ledger cache. quarkus.redis.timeout is 200ms. RedisTimeoutConfigTest passed: 1 test, 0 failures. Quarkus dev live-reloaded in 3.700s and /actuator/health stayed 200.


## Cloud Elasticsearch timeout, 2026-09-27
Cloud traffic search calls are bounded to 800ms connect and 800ms socket, matching Spring. ElasticsearchTimeoutConfigTest passed: 1 test, 0 failures. Traffic was restarted on 18083 with local-dev.yml. Port 9200 was not listening. Gateway GET /api/payments?page=1&size=5 returned 200 in 257.3ms with a 9145-byte body, so the MySQL fallback still answered inside the bound.


## Quarkus SQL statement timeout, 2026-09-27
New Quarkus JDBC connections run SET SESSION max_execution_time=3000, so online statements stop after 3 seconds. SqlStatementTimeoutConfigTest passed: 1 test, 0 failures. Dev mode live-reloaded in 4.763s. /actuator/health then returned 200, which opens a MySQL connection, so the session statement did not reject new connections.


## Quarkus offense dead letter, 2026-09-27
offense_create and offense_update keep their channel names. Their failure strategy is dead-letter-queue, and the topics are the existing offense_create.DLT and offense_update.DLT. SmallRye 4.37 only offers fail, ignore, or dead-letter-queue, so a failed record goes to the DLT instead of being redelivered without a cap. OffenseDeadLetterConfigTest passed. Dev mode live-reloaded in 3.288s and /actuator/health stayed 200.


## Spring redis split live, 2026-09-27
Spring now runs on 9080 with the cache Redis factory primary at 300ms and the blacklist factory at 200ms. The first start failed because both factories were candidates for the cache manager; redisConnectionFactory is now @Primary. /actuator/health first returned 503 because DataRedisHealthIndicator could not parse INFO from Redis 5.0.14, while login still returned 200. Dev health for Redis is disabled, matching Elasticsearch. After restart, /actuator/health returned 200 and admin login returned 200.

## Cloud Redis split, 2026-09-27
Other Cloud services no longer share one 200ms Redis client. SplitRedisConnectionConfiguration runs before DataRedisAutoConfiguration. The primary client is cache commands at 300ms. blacklistRedisConnectionFactory is 200ms. A configured spring.data.redis.timeout of 200ms does not change those bounds. User, audit, system, AI, and RAG JWT checks inject the blacklist factory. Auth's RedisTemplate does too, because auth Redis is the token blacklist. Traffic already had its own split and is left in place. SplitRedisConnectionConfigurationTest passed: 2 tests, 0 failures. Gateway, auth, user, traffic, audit, system, AI, and RAG compiled. Cloud processes were not listening, so this is not a live scrape.
## Cloud and Quarkus consumer cap, 2026-09-27
Cloud user, traffic, audit, and system listener factories now use LedgerKafkaSettings. A failed record is retried at most 3 times, then published to the existing topic plus .DLT. Illegal argument and JSON parse failures are not retried. User, audit, and system producers now use the same bounded settings as traffic: acks all, idempotent producer, retries 3, delivery.timeout.ms 10000. LedgerKafkaSettingsTest passed: 2 tests, 0 failures. DevKafkaConfigurationTest passed: 1 test, 0 failures. The four modules compiled and the reactor build succeeded.
Quarkus offense_create and offense_update keep those channel names and the existing offense_create.DLT and offense_update.DLT topics. The listener retries a failed business call 3 times in a new transaction each time, then the failure strategy publishes the existing DLT. Poison JSON is not retried. ConsumerAttemptsTest passed: 3 tests, 0 failures. OffenseDeadLetterConfigTest passed: 1 test, 0 failures. Other Quarkus channels still have no dead-letter topic configured.
## Quarkus consumers capped, 2026-09-27
Every Quarkus @Incoming channel now fails into <channel>.DLT after the listener retries the business call at most 3 times. Channel names are unchanged, including offense_create. Deserialization failures are not retried. The service method keeps its own transaction, so a failed attempt rolls back before the next try. ConsumerDeadLetterConfigTest passed: 1 test, 0 failures, covering at least 28 channels. ConsumerAttemptsTest passed: 4 tests, 0 failures. OffenseDeadLetterConfigTest passed: 1 test, 0 failures.
## Payment Kafka failure counter, 2026-09-27
Go and Quarkus payment creation now publish payment_record_create after the MySQL commit. A publish failure increments kafka_publish_failed_total and does not change the HTTP result. Quarkus uses payment-create-out with acks all, retries 3, delivery.timeout.ms 10000, and an idempotent producer. Go uses an async kafka-go writer, acks all, at most 4 attempts, and a 10 second write timeout. kafka-go 0.4.51 has no Java idempotent-producer switch. PaymentEventPublishTest passed: 2 tests, 0 failures. Go payment package tests passed, including TestPublishFailureIsCountedAndDoesNotEscape.
## Gateway dev timeouts, 2026-09-27
The dev route list replaces the main list, so AI and RAG had lost their 8 second response timeout. application-dev.yml now sets httpclient response-timeout to 3 seconds for business routes, and metadata response-timeout 8000 on rag-service and ai-service. Neither gateway YAML configures a Retry filter. GatewayRouteContractTest passed: 1 test, 0 failures.
## Quarkus producer bounds, 2026-09-27
SmallRye only treats acks and retries as connector attributes. delivery.timeout.ms, enable.idempotence, request.timeout.ms, max.block.ms, and max.in.flight are supplied by the ledger-producer Kafka client map. offense-create-out, offense-update-out, and payment-create-out use that map, with acks all and retries 3. The previous dotted payment properties were not connector settings and were removed. LedgerKafkaClientConfigTest passed: 2 tests, 0 failures. Go still has no idempotent-producer switch in kafka-go 0.4.51.
## Ledger reconcile action, 2026-09-27
Spring already exposed POST /actuator/ledgerReconcile. Cloud traffic now exposes the same actuator write operation, limited to ADMIN or SUPER_ADMIN. Quarkus exposes POST /actuator/ledgerReconcile for those roles. Go exposes the same path after authentication and rejects non-admins with 403. Each action marks PROCESSING rows older than 2 minutes SUCCESS when the ledger row exists and FAILED when it does not. Go TestLedgerReconcileRequiresAdminAndReportsCount passed. Cloud traffic compiled. Quarkus main sources compiled.
## Go ledger idempotency, 2026-09-27
Fine, deduction, and appeal creates no longer use the in-memory map that ignored a missing key. They reserve sys_request_history through the same MySQL decider as payments. Missing Idempotency-Key on those creates, and on appeal update, is 400. Replay is 208, a different body is 409, and in-progress is 409 with Retry-After 1. Handler tests passed. Go still has no POST /api/appeals/:appealId/reviews endpoint; appeal update is the decision write that now carries the key.
## Go appeal decision, 2026-09-27
POST /api/appeals/:id/reviews now creates an appeal_review row. A missing Idempotency-Key is 400. The write reserves sys_request_history as APPEAL_REVIEW_CREATE, so reconciliation can mark it SUCCESS only when review_id exists. Replay, conflict, and in-progress use the same ledger error mapping as payments. TestCreateReviewRequiresIdempotencyKey passed. The appeal service package compiled.
## Ledger key required, 2026-09-27
Cloud traffic and Quarkus now reject a ledger POST that has no Idempotency-Key with 400 before the write. The paths match Spring: payments, fines, deductions, appeals, and appeal reviews. Quarkus accepts the path with or without a leading slash. LedgerKeyPolicyTest passed on both: 1 test each, 0 failures.
## Go workflow ledger keys, 2026-09-27
Payment and appeal workflow events no longer use the in-memory idempotency map. Both reserve sys_request_history. The fingerprint is the record id plus the event, so the same key with a different event is 409. A missing Idempotency-Key is 400. A rejected transition is marked FAILED and still returns 409. The statemachine package compiled and handler tests passed.

## Workflow ledger keys, 2026-09-27
Cloud traffic and Quarkus now require Idempotency-Key on payment and appeal workflow POSTs. A missing key is 400 before the write. The history row uses business type PAYMENT_STATUS or APPEAL_STATUS, and the fingerprint is the record id plus the event. The same event replays as 208. A different event is 409. In progress is 409 with Retry-After 1. A rejected transition is marked FAILED and still returns 409, so that key can be retried. Offense workflow is unchanged. WorkflowEventLedgerTest passed on both: 3 tests, 0 failures. LedgerKeyPolicyTest passed: 1 test each, 0 failures.
Spring payment workflow no longer treats every existing history row as 208. It reserves sys_request_history before the transition, with the same id-plus-event fingerprint. Appeal workflow now requires the header. A rejected transition is marked FAILED. Replay, conflict, and in-progress still go through the existing exception handler: 208, 409, and 409 with Retry-After 1. Spring main sources compiled.

## Quarkus trace id, 2026-09-27
Quarkus now reads X-Trace-Id and returns the same value. A missing or blank header gets a new 16 character id, and that id is also written back onto the request. TraceIdsTest passed: 1 test, 0 failures. The main sources compiled.

## Cloud trace id reaches every service, 2026-09-27
Auth, audit, search, and AI now scan com.tutict.finalassignmentcloud.observability, so the shared TraceIdFilter runs there. User, traffic, system, and RAG already scanned the parent package. The console log level pattern includes traceId on the gateway and every service. CloudTraceCoverageTest passed: 1 test, 0 failures. Auth, audit, AI, and search compiled.

## Health details hidden, 2026-09-27
Spring public /actuator/health no longer uses when-authorized. show-details is never, so an authenticated caller does not see component details. Cloud auth, user, traffic, audit, system, AI, search, RAG, the gateway, and local-dev already or now set show-details never. HealthDetailsConfigTest and CloudHealthDetailsTest passed: 1 test each, 0 failures.

## Cloud pool shed on every service, 2026-09-27
Auth, user, audit, system, AI, search, and RAG now use PoolLoadShedFilter. A non-ledger GET returns 503 with Retry-After 1 when that service Hikari pool is at least 80 percent busy. Ledger writes still wait unless the pool has no idle connection or a thread is already waiting. Traffic keeps its own filter and marks the request handled so the shared filter does not shed twice. RELIABILITY_LOAD_SHED defaults to true in local-dev. PoolShedPolicyTest passed: 1 test, 0 failures. Traffic compiled.

## Quarkus connection wait, 2026-09-27
A ledger write that cannot get a MySQL connection now returns 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. The check walks the exception cause chain, so a MyBatis wrapper around an acquisition timeout is included. GET and non-ledger POST stay 500. LedgerConnectionPolicyTest passed: 1 test, 0 failures. The main sources compiled.

## Go connection wait, 2026-09-27
Ledger create, payment, and workflow errors that are dial timeouts, pool failures, or too many connections now return 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. Other errors stay 500. TestConnectionWaitRecognizesPoolAndDialFailures and TestWriteLedgerErrorMapsConnectionWait passed.

## Cloud auth revocation cache, 2026-09-27
Cloud auth now keeps a process-local revocation cache. A known revoked token is 401 even when Redis is down. A write, login, or refresh whose revocation state cannot be checked is 503 with Retry-After 1. An ordinary GET with an unknown token still proceeds. BlacklistAccessPolicyTest passed: 1 test, 0 failures. The auth module compiled.

## Cloud service revocation, 2026-09-27
Traffic, user, audit, system, AI, search, and RAG share ServiceJwtAuthenticationFilter. It now reads the same blacklist:<sha256> key that auth writes. A revoked token is 401. If Redis cannot answer, a write is 503 with Retry-After 1, and a GET still proceeds unless this process already saw the revocation. ServiceRevocationTest passed: 1 test, 0 failures. The common module compiled.

## Quarkus model fallback bound, 2026-09-27
The Quarkus chat stream now falls back when the model produces no token or fails within 1 second. The response contains isFallback true and increments ai_fallback_total. The chat/stream collect wait is 2 seconds instead of 45. AiStreamGuardTest passed: 2 tests, 0 failures. The main sources compiled.

## Go model header timeout, 2026-09-27
The Go model client now fails if response headers do not arrive within 1 second. Dial timeout stays 1 second. A stream that fails to start returns HTTP 200 with isFallback true and increments the AI fallback counter. An error event from the provider is marked the same way. A started stream can still run under the existing 2 minute request context. TestModelResponseHeadersFailWithinOneSecond passed. The handler package compiled.

## Model connect timeout, 2026-09-27
Spring OpenAI-compatible calls and Cloud Ollama and OpenAI-compatible calls now use a 1 second TCP connect timeout. A failed AI stream is an error event with isFallback true and counts as an AI fallback. The existing message field is unchanged. SseEventSerializationTest passed: 4 tests, 0 failures. Cloud AI compiled.

## Cloud auth login limit, 2026-09-27
POST /api/auth/login on the auth service now uses LoginAttemptGuard. The ninth attempt for one account returns 429 with Retry-After 120. A public remote address locks at 40 attempts per minute. Loopback, which is how the gateway reaches auth, does not add a second IP bucket, so the gateway keeps the per-client IP limit. The account key no longer includes the IP. LoginAttemptGuardTest passed: 1 test, 0 failures. The auth module compiled.

## Gateway CORS origins, 2026-09-27
The gateway allow-list now matches Spring: ports 3000, 8080, 5173, 15173, and 13000 on localhost and 127.0.0.1. The dev profile states the same list, so replacing the route table does not drop it. Credentials stay enabled and X-Trace-Id stays exposed. GatewayRouteContractTest passed: 1 test, 0 failures.

## Browser CORS lists, 2026-09-27
Go no longer answers the proxy with Access-Control-Allow-Origin *. The API and the proxy echo only the Spring origin list, including ports 8080, 5173, 15173, 3000, and 13000, and they allow Idempotency-Key and X-Trace-Id. Quarkus now enables that same explicit list with credentials. TestCorsPreflightAllowsReactLoginOrigin passed. CorsConfigTest passed: 1 test, 0 failures.

## Concurrent workflow reserve, 2026-09-27
Cloud and Quarkus workflow ledgers now have a concurrent reserve test. Eight callers use one key and one event. Exactly one insert wins. The other seven are replay or in-progress, so none of them starts a second write. WorkflowEventLedgerTest passed on both: 4 tests, 0 failures. Go already covers the same race against MySQL in TestConcurrentReserveSingleWinner.

## Spring concurrent reserve, 2026-09-27
Spring LedgerHistoryReserve now has the same race test. Eight callers use one key and one fingerprint. The fake mapper lets one insert win and rejects the rest as duplicates. Exactly one reserve returns. The other seven are replay or in-progress, and the stored row stays PROCESSING. LedgerHistoryReserveTest passed: 1 test, 0 failures.

## Go ledger connection acquire, 2026-09-27
Go ledger writes now borrow a MySQL connection for at most 200ms, then run the statement for at most 3 seconds. A pool wait past 200ms is context.DeadlineExceeded and the existing handlers return 503 with Retry-After 1. Reads are unchanged. Payment create and update, fine and deduction create and update, appeal create, update, and review, and payment and appeal workflow events use that borrow. Reserve, mark success, and mark failed do too. TestLedgerAcquireTimeoutAbortsTheWrite and TestLedgerAcquireTimeoutIs200ms passed. The reliability, config, payment, offense, and handler packages passed.

## Quarkus logout blocks payment, 2026-09-27
Logout now has a direct test. It revokes the caller's refresh tokens and blacklists the access token for its remaining life. Redis is down in the test, so the blacklist write fails closed and logout throws. The same process still remembers the token. POST /api/payments with that bearer token returns 401. A different token, whose revocation Redis cannot answer, returns 503 with Retry-After 1. LoggedOutPaymentTest passed: 1 test, 0 failures.

## Quarkus reliability config is versioned, 2026-09-27
application.properties is gitignored, so a clean checkout was losing the reliability contract. Those settings now live in application.yaml. CORS is the same explicit Spring origin list with credentials, not any localhost port. New MySQL connections set max_execution_time=3000 and the pool acquisition timeout is 200ms. Cache Redis commands time out at 300ms. The blacklist uses its own client at 200ms. Prometheus and ledger reconcile require ADMIN or SUPER_ADMIN. Incoming channels still fail into <channel>.DLT, and the payment and offense producers still use the bounded idempotent client. RELIABILITY_LOAD_SHED defaults to true and TOKEN_BLACKLIST_FAIL_OPEN defaults to false. ConsumerDeadLetterConfigTest, OffenseDeadLetterConfigTest, LedgerKafkaClientConfigTest, SqlStatementTimeoutConfigTest, RedisTimeoutConfigTest, CorsConfigTest, and LoggedOutPaymentTest passed: 8 tests, 0 failures.

## Go payment producer budget, 2026-09-27
The Go payment producer still uses kafka-go 0.4.51, which has no idempotent-producer switch. It already required acks from all replicas. Each attempt previously waited 10 seconds, and four attempts could run for about 40 seconds. A send is now one try plus 3 retries. Each try waits at most 2 seconds, inside the 3 second request bound. Backoff is 100ms, 400ms, then 500ms. The worst case is 9 seconds, inside the 10 second delivery budget. The publish stays asynchronous, so a Kafka failure still does not decide the payment. TestPaymentProducerStaysInsideDeliveryTimeout passed. The payment package passed.

## Spring request and pool metrics, 2026-09-27
Spring now counts request results as http_responses_2xx_total, http_responses_4xx_total, and http_responses_5xx_total. The guard filter records shed responses, missing ledger keys, dependency timeouts, and the status after the rest of the chain. db_pool_wait_count is the Hikari threads waiting for a connection, or 0 when the pool is not a Hikari pool. ReliabilityGuardFilterTest passed: 4 tests, 0 failures.

## Cloud request and pool metrics, 2026-09-27
Auth, user, audit, system, AI, search, and RAG now count request results. ResponseResultFilter records http_responses_2xx_total, http_responses_4xx_total, and http_responses_5xx_total after the chain, including a shed 503. Traffic already counts those statuses and marks the request handled, so the shared filter does not count them twice. The same services expose db_pool_wait_count from Hikari threads waiting for a connection. Search has no pool, so the gauge stays 0. Traffic keeps the same gauge name through the shared component. ResponseResultFilterTest passed: 1 test, 0 failures. The common module test run passed.

## Gateway request metrics, 2026-09-27
The Cloud gateway now counts request results as http_responses_2xx_total, http_responses_4xx_total, and http_responses_5xx_total. The filter runs before the login limiter, so a 429 is counted as well as a downstream 200. A chain failure with no status counts as 5xx. Gateway prometheus stays unexposed because this process has no admin authentication; public health is unchanged. GatewayResponseMetricsTest passed: 1 test, 0 failures.

## Spring login account limit, 2026-09-27
Spring's per-account login limit no longer includes the client address. The same account is locked on the 9th attempt even when each attempt comes from a different address. A spoofed X-Forwarded-For header is ignored unless the direct peer is a trusted proxy, and the default trusted list is empty. The address bucket is unchanged: 40 attempts from one address lock for 2 minutes. LoginAttemptGuardTest passed: 2 tests, 0 failures.

## Cloud sharding SQL cap, 2026-09-27
Traffic's own default profile is sharding, and that profile had no statement cap. Both shard pools now use a 250ms connection timeout, which is Hikari's floor, and sessionVariables max_execution_time=3000. The dev profile and local-dev overlay already had the statement cap. CloudSqlTimeoutConfigTest passed: 1 test, 0 failures. Common and traffic compiled.

## Go default DB is shared traffic, 2026-09-27
Go's default database name was still cesi (Quarkus schema), so the Go backend was using the wrong table. It now falls back to traffic unless MYSQL_DATABASE is explicitly set. The start-dev runner now hard-codes the JDBC URL to traffic and the README documents the shared DB. The gorm timeout test and the default-DSN test now pass. The Go backend and configs modules pass.

## Appeal decision key, 2026-09-27
Updating an appeal or an appeal review now requires Idempotency-Key on Spring, Cloud, and Quarkus, the same as Go. A missing key is 400 before the write. The key is still required on payment, fine, deduction, and appeal creates, and on payment and appeal workflow events. Fine and deduction updates stay optional. ReliabilityGuardFilterTest passed: 5 tests, 0 failures. LedgerKeyPolicyTest passed on Cloud and Quarkus: 1 test each, 0 failures.

## Login failure does not sleep, 2026-09-27
Spring and Cloud no longer call Thread.sleep after a failed login. The old penalty began at 750ms on the second failure and could reach 10 seconds, which held the login request open. A wrong password is now a normal 401. The lock is unchanged: 8 attempts per account per minute, 40 per address per minute, and a 2 minute lock. The ninth attempt is still 429 with Retry-After around 120 seconds. Cloud login still enforces that limit in inspect and does not call recordFailure; the method itself no longer sleeps if it is called. LoginAttemptGuardTest passed on Spring: 3 tests, 0 failures. LoginAttemptGuardTest passed on Cloud auth: 2 tests, 0 failures. The Spring login contract tests now see the test Redis mock as blacklistRedisTemplate, which the test profile needs because the real Redis config is disabled. LoginThrottleContractIntegrationTest passed: 2 tests, 0 failures. RateLimitProxyHeaderIntegrationTest passed: 1 test, 0 failures.

## Embedding connect timeout, 2026-09-27
Spring Ollama embeddings, Spring OpenAI-compatible embeddings, and Cloud RAG Ollama embeddings now open the TCP connection with a 1 second timeout. The provider request timeout stays 60 seconds after the connection is up, so a live model can still finish an embedding. A dead address no longer keeps the 60 second provider timeout. OllamaEmbeddingConnectTimeoutTest passed on Spring and on Cloud RAG: 1 test each, 0 failures. Cloud RAG also declares the Redis starter its service JWT filter already uses.

## Go payment producer is idempotent, 2026-09-27
kafka-go 0.4.51 writes producer id -1, so it cannot be an idempotent producer. The Go payment publisher now uses franz-go 1.20.7, which enables idempotent writes unless they are explicitly disabled. The topic is still payment_record_create. Acks stay all. Record retries are 3, each request waits at most 2 seconds, and the delivery timeout is 10 seconds. Publish stays asynchronous, so a Kafka failure still does not decide the payment. TestPaymentProducerStaysInsideDeliveryTimeout and TestPublishFailureIsCountedAndDoesNotEscape passed. The payment package passed.

## After: Go, 2026-09-27, idempotent producer, 5 minutes
Backend http://127.0.0.1:18080, binary artifacts/go-backend-idempotent.exe. It uses the existing MySQL traffic database, Redis on 6379, and Kafka on 9092. GO_DOCKER_SERVICES_ENABLED=false, so it did not start its own containers. Same profile as the 2026-09-26 acceptance run: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/go-after-idempotent-5m.json.
requests=61635. http_req_failed_rate=0. checks_rate=1.000. avg=2.3ms. p95=3.8ms. p99=15.5ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
checks passes=61937 fails=0. Targets were not loosened.

## After: Cloud, 2026-09-27, ports outside excluded range, 5 minutes
Gateway http://127.0.0.1:18090, same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/cloud-after-ports-5m.json.
requests=48792. http_req_failed_rate=0. checks_rate=1.000. avg=16.9ms. p95=45.2ms. p99=60.4ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Checks passes=49094 fails=0. Targets were not loosened.

## After: Quarkus, 2026-09-27, dev server restarted, 5 minutes
Backend http://127.0.0.1:19080, quarkusDev. The previous dev process was returning the hot-reload error page. It was restarted against MySQL traffic, Redis 6379, and Kafka 9092. The HTTP port is 19080 and the websocket proxy is 19181, so they do not bind the same port. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/quarkus-after-20260927-5m.json.
requests=51935. http_req_failed_rate=0. checks_rate=1.000. avg=12.4ms. p95=45.8ms. p99=78.5ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Checks passes=52237 fails=0. This is still dev mode, not a packaged jar. Targets were not loosened.

## After: Spring, 2026-09-27, running process, 5 minutes
Backend http://127.0.0.1:9080. The process is the one already listening on 8080 and 9080; it was not rebuilt for this run. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/spring-after-20260927-5m.json.
requests=49631. http_req_failed_rate=0. checks_rate=1.000. avg=15.7ms. p95=26.7ms. p99=45.1ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Checks passes=49933 fails=0. Targets were not loosened.

## Cloud dev ports avoid the excluded range, 2026-09-27
Windows excludes TCP 8085-8184 on this machine, so system, AI, search, and RAG could not bind their old defaults. Dev defaults are now 18085, 18086, 18087, and 18088. The start scripts use the same defaults. AI is listening on 18086 and search on 18087. The gateway was restarted with those ports. GET /api/ai/chat/actions through the gateway returned 200 in 267ms. The ledger profile was run again for 5 minutes at user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/cloud-after-system-5m.json.
requests=48138. http_req_failed_rate=0. checks_rate=1.000. avg=17.9ms. p95=48.0ms. p99=67.8ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Checks passes=48440 fails=0. Targets were not loosened.

## Backup drill, 2026-09-27
scripts/reliability/backup-traffic.ps1 wrote artifacts/backups/traffic-20260927-205659.manifest.txt. This MySQL build rejects SHOW BINARY LOG STATUS, and that probe used to print an error and could stop the script. The probe is now optional and falls back to SHOW MASTER STATUS. The second backup exited 0. restore-traffic-scratch.ps1 loaded that dump into traffic_restore_drill and exited 0. The checksum matched. Live traffic payment_record stayed 13 rows.

## Quarkus q health and metrics, 2026-09-27
Quarkus again serves GET /q/health and GET /q/health/ready. Both ping MySQL and return only status UP or DOWN. Liveness stays UP without a database call. GET /q/metrics is the same Prometheus text as /actuator/prometheus and requires ADMIN or SUPER_ADMIN. Anonymous /q/metrics returned 401. An admin token returned 200 and the body included backup_last_success_timestamp. The duplicate --release 23 compiler argument was removed so dev-mode reload does not pass a bare 23 to javac. The dev server was restarted on 19080.

## Quarkus logout with JSON body, 2026-09-27
POST /api/auth/logout now accepts JSON (no body required) and returns 200. The old bearer token is blacklisted, so subsequent payment creation returns 401. The probe payment was created with a different idempotency key and has been deleted.


## Ledger connection wait reaches 503, 2026-09-27
A ledger write that cannot get a MySQL connection was still able to miss the 503 contract. Spring and Cloud open the connection inside the transaction, so Hikari's pool timeout arrives as CannotCreateTransactionException with SQLTransientConnectionException underneath. The specific handler never saw that wrapper, and the generic handler returned 500 without Retry-After. Both handlers now walk the cause chain. A ledger POST or PUT or DELETE returns 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. A GET, a non-ledger POST, and a transaction failure that is not a pool wait stay 500. Cloud traffic's advice is ordered ahead of the shared generic handler, and the shared handler has the same 503 branch so another service cannot turn the wrapper into a bare 500. Hikari still rejects a connection timeout below 250ms, so the pool floor stays 250ms. A size-1 pool against local traffic produced that wrapper, and the Spring handler mapped it to 503. LedgerConnectionPolicyTest passed: 2 tests, 0 failures. LedgerConnectionTimeoutMappingTest passed: 4 tests, 0 failures, 0 skipped. LedgerConnectionSignalsTest passed: 2 tests, 0 failures. LedgerConnectionPolicyTest and LedgerConnectionTimeoutAdviceTest passed on Cloud traffic: 2 and 3 tests, 0 failures. Targets were not loosened.

Go's default GORM transaction borrowed a connection in BEGIN before the 200ms callback, and that callback then saw an open transaction and returned. The ledger pool now borrows for at most 200ms and only then starts the transaction on that connection. The transaction context is not cancelled at 200ms, so a statement can still run to the 3 second cap. A non-ledger begin does not use the 200ms borrow. TestLedgerBeginWaitsAtMost200ms and TestNonLedgerBeginDoesNotUseTheAcquireTimeout passed. The reliability package and the Go config package passed. Quarkus already walks the cause chain, and its pool acquisition timeout is 200ms. The Spring process on 9080 and 8080, the Go process on 18080, and Cloud traffic on 18083 were not restarted, so this result is the test proof, not a new five-minute k6 run.

## Go ledger pool is the live 18080 process, 2026-09-27
The process that had been listening on 18080 was artifacts/go-backend-idempotent.exe, started at 19:39, before the ledger pool. It was stopped. artifacts/go-backend-ledger-pool.exe now listens on 18080, with GO_DOCKER_SERVICES_ENABLED=false, MySQL traffic, Redis 6379, and Kafka localhost:9092. GET /actuator/health returned 200 and status UP. POST /api/auth/login for admin returned 200. TestLedgerPoolCommitsAndReturnsTheConnection had already passed against traffic, so a ledger create commits and returns the connection. Spring on 9080 and Cloud traffic on 18083 were started before the transaction-wrapper 503 mapping and were not restarted in this step. Targets were not loosened.

## Cloud traffic restarted with the connection-wait build, 2026-09-27
The traffic process on 18083 was the 14:50 jar, started before the transaction-wrapper 503 mapping. Replacing that jar failed until Nacos config was disabled the same way as system, AI, search, and RAG: config, discovery, and import-check off. The first boot then failed because WorkflowEventLedger has two constructors and Spring could not choose one. The mapper constructor is now @Autowired. Dev profile health also left the Redis indicator on, and this host's Redis 5 INFO parse marks the process DOWN. application-dev.yml now defaults management.health.redis.enabled to false, and leaves Elasticsearch health off, matching local-dev.yml. The rebuilt jar is process 38180 on 18083. GET /actuator/health returned 200 and status UP. Through the gateway on 18090, admin login returned 200 and GET /api/payments?page=1&size=1 returned 200. Spring on 9080 is still the 15:16 process and does not yet have this mapping. Targets were not loosened.

## Spring restarted with the connection-wait classes, 2026-09-27
The process on 9080 and 8080 was started at 15:16, before the transaction-wrapper 503 mapping. It was stopped. The replacement is spring-boot:run with profile dev, the same MySQL traffic URL, Redis timeouts, Hikari pool size, and TOKEN_BLACKLIST_FAIL_OPEN=false. AI_AGENT_DRAFT_STORE=memory, which is how the previous process kept the draft store off Redis. Devtools restart is off. Tomcat is on 9080 and the network listener is on 8080, both pid 4744. GET /actuator/health returned 200. POST /api/auth/login for admin returned 200. Targets were not loosened.

## Spring overload shed after restart, 2026-09-27
Backend http://127.0.0.1:9080, the spring-boot:run process started after the connection-wait mapping. k6 scripts/k6/ledger-shed.js, 40 constant VUs, 15 seconds. Summary artifacts/k6/ledger-shed-spring-after-restart.json and artifacts/k6/ledger-shed-spring-after-restart.log.
checks_succeeded=100.00% (58980/58980). shed_503=36626. Every 503 carried Retry-After 1. The replay check passed: a second POST with the same key and body was not another 201. The run inserted 4414 pending shed payments of 1.00. Those rows and their sys_request_history keys were deleted afterward. payment_record is 13 rows and 809.00 again. fine 1 paid_amount stayed 202.00. Targets were not loosened.

## Overload shed on Cloud and Go, 2026-09-27
The same 15 second ledger-shed script, default 40 VUs. Cloud gateway http://127.0.0.1:18090: checks 99.94% (17246/17256), shed_503=4424, exit 0. Summary artifacts/k6/ledger-shed-cloud-after-restart.json. Go http://127.0.0.1:18080 at 40 VUs kept every request inside the 50-connection pool, so shed_503=0 and the script's count>0 threshold exited 99. Checks were 99.95%. That run does not show a missing Retry-After.
Go at 200 VUs first returned 31667 sheds, but 1958 first payments were outside 201, 208, 400, 409, and 503 with Retry-After. Those were database lock waits and deadlocks reported as 500. ConnectionWait now treats deadlock, lock wait timeout, context deadline, invalid connection, connection reset, and broken pipe as a shed. The Go process was rebuilt and restarted on 18080. The repeat at 200 VUs was checks 100.00% (44872/44872), shed_503=556, exit 0. Summary artifacts/k6/ledger-shed-go-200vu-lock.json.
Quarkus http://127.0.0.1:19080 at 40 and 200 VUs stayed at checks 100% with shed_503=0. The script threshold still wants one 503, so those exits are 99. That process was not restarted for this. Probe payments with payer name shed were deleted. payment_record is 13 rows and 809.00. fine 1 paid_amount is 202.00. Targets were not loosened.

## Quarkus overload, 2026-09-27
Quarkus on 19080 at 40 and 200 VUs completed the ledger-shed script with checks 100% and shed_503=0. The requests finished before the 200ms pool wait, so not shedding was consistent with the contract. At 800 VUs the same process returned 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT, and also bare 500s. Lock wait, deadlock, and a Redis client wait-queue overflow were not recognized as dependency timeouts. They are now. A dependency timeout on a read is 503 as well, not only a ledger write. The dev process was restarted on 19080 with the post-quantum key placeholders left blank. The JDBC pool max size is explicitly 20. After that reload, 800 VUs produced shed_503=1182 and the payment checks passed, but 841 reads failed while the process was still reloading and refusing connections. A later steady 200 VU run was checks 100.00% (6368/6368), shed_503=0, no refused connections, exit 99 only because the script requires one 503. Probe rows named shed were deleted. payment_record is 13 rows and 809.00. fine 1 paid_amount is 202.00. Targets were not loosened.

## Quarkus sheds before the accept queue fills, 2026-09-27
Sampling the Agroal pool at the start of a request missed a burst: every request passed the filter before any connection was checked out, so 200 VUs finished inside 200ms and the script saw no 503. At 800 VUs the accept queue then refused connections, which k6 counts as failures. The filter now counts requests in flight. A ledger write or a non-ledger GET is 503 with Retry-After 1 when more requests are in flight than the pool max of 20. Health and ledger reads are not shed by that count. After live reload, 200 VUs for 8 seconds against http://127.0.0.1:19080 gave checks 100.00% (153512/153512), shed_503=112442, no refused connections, exit 0. Summary artifacts/k6/ledger-shed-quarkus-inflight.json. Replay did not create a second payment. Shed rows were deleted. payment_record is 13 rows and 809.00. fine 1 paid_amount is 202.00. Targets were not loosened.

## After: Quarkus, 2026-09-27, in-flight shed, 5 minutes
Backend http://127.0.0.1:19080, quarkusDev after the in-flight shed and the single fail-open setting. The duplicate app.security.token-blacklist.fail-open=false line was removed from application.properties; the value stays false. Profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/quarkus-after-inflight-5m.json and artifacts/k6/quarkus-after-inflight-5m.log.
requests=49971. http_req_failed_rate=0. checks_rate=1.000. avg=14.9ms. p95=56.7ms. p99=94.4ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Exit 0. The normal 16 VU profile did not trip the in-flight shed. Targets were not loosened.

## After: Spring, 2026-09-27, restarted process, 5 minutes
Backend http://127.0.0.1:9080, the spring-boot:run process that has the connection-wait mapping. The earlier spring-after-20260927-5m.json run was the 15:16 process. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/spring-after-restart-5m.json and artifacts/k6/spring-after-restart-5m.log.
requests=48589. http_req_failed_rate=0. checks_rate=1.000. avg=17.9ms. p95=31.8ms. p99=72.8ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Exit 0. Targets were not loosened.

## Cloud without static discovery, 2026-09-27
Traffic on 18083 was the rebuilt jar with Nacos config, discovery, and import-check disabled, but it was not given config/local-dev.yml. Feign then had no instance for finalassignmentcloud-user. Driver-scoped reads returned 400 or 500. The 5 minute profile against http://127.0.0.1:18090 is artifacts/k6/cloud-after-traffic-restart-5m.log and artifacts/k6/cloud-after-traffic-restart-5m.json.
requests=56165. http_req_failed_rate=0.656. checks_rate=0.347. p95=42.0ms. p99=77.1ms.
health_ok=1.000. user_read_ok=0.125. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
This run is not acceptance. Targets were not loosened.

## After: Cloud, 2026-09-27, static discovery in the dev profile, 5 minutes
The dev profile now lists the same static instances as config/local-dev.yml, including finalassignmentcloud-user at http://127.0.0.1:18082. Nacos stays disabled. StaticDiscoveryConfigTest passed: 1 test, 0 failures. Traffic was packaged and restarted on 18083 with that profile and the local-dev overlay. A direct driver read of offenses, fines, deductions, appeals, and payments returned 200 before the load run. Gateway http://127.0.0.1:18090. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/cloud-after-static-discovery-5m.log and artifacts/k6/cloud-after-static-discovery-5m.json.
requests=45761. http_req_failed_rate=0. checks_rate=1.000. avg=22.3ms. p95=63.3ms. p99=91.7ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Exit 0. The cloud-after-traffic-restart-5m run above is not the acceptance result. payment_record stayed 13 rows and 809.00. fine 1 paid_amount stayed 202.00. Targets were not loosened.

## After: Go, 2026-09-28, ledger pool, 5 minutes
Backend http://127.0.0.1:18080, binary artifacts/go-backend-ledger-pool.exe. This is the process that treats deadlock, lock wait, context deadline, invalid connection, connection reset, and broken pipe as a shed. The earlier go-after-idempotent-5m.json run was before that binary. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/go-after-ledger-pool-5m.log and artifacts/k6/go-after-ledger-pool-5m.json.
requests=62195. http_req_failed_rate=0. checks_rate=1.000. avg=1.3ms. p95=2.4ms. p99=3.9ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Stderr was empty and every scenario finished. payment_record stayed 13 rows and 809.00. fine 1 paid_amount stayed 202.00. Targets were not loosened.

## Stack restarted, 2026-09-28
Docker Desktop was not running and the four backends were down. The stale `run` directory could not be deleted because Windows cannot remove the `dockerInference` socket. It was renamed to `run.broken-20260928-0008`. That is not a factory reset. Docker Desktop 4.47 then started, engine 28.4.0. Redpanda and Elasticsearch were started from the existing containers and both reported healthy. Nacos was left stopped. Local redis-server is listening on 127.0.0.1:6379; the Redis container was not started because that port is already taken.
Go `artifacts/go-backend-ledger-pool.exe` is on 18080. Spring dev is on 9080 and 8080 with `TOKEN_BLACKLIST_FAIL_OPEN=false`. Quarkus dev is on 19080. Cloud was started with `scripts/start-cloud-backend.ps1 -SkipBuild -IncludeAi -GatewayPort 18090` and `CLOUD_USE_NACOS=false`, so `config/local-dev.yml` is loaded. Gateway health is UP. `ce@ce.com` `GET /api/offenses/driver/6` through the gateway returned 200. These processes do not replace the 5 minute acceptance runs already recorded. Targets were not loosened.

## Cloud AI fallback metric, 2026-09-28
The AI process started from the 2026-09-26 20:19 jar. Its Prometheus scrape had no `ai_fallback_total`. `AiFallbackMetrics` registers that counter, and `AiFallbackMetricsTest` passed: 1 test, 0 failures. The dev profile now also lists the static service instances, with Nacos left disabled. The module was packaged and restarted on 18086. `GET /actuator/health` returned 200. Admin `GET /actuator/prometheus` includes `ai_fallback_total 0.0`. An anonymous scrape returned 401. Targets were not loosened.

## Cloud stale jars replaced, 2026-09-28
The processes started with `-SkipBuild` were still the 2026-09-26 jars, except auth from 2026-09-27 01:26. Those jars did not contain `GatewayResponseMetrics`, `BlacklistAccessPolicy`, or `PoolLoadShedFilter`. Gateway, auth, user, audit, system, search, and RAG were packaged and restarted on 18090, 8081, 18082, 8084, 18085, 18087, and 18088. Nacos stayed disabled and `config/local-dev.yml` was loaded. Traffic on 18083 and AI on 18086 were left on the jars built earlier today. Gateway login for `ce@ce.com` returned 200, and `GET /api/offenses/driver/6` returned 200. User Prometheus now includes `load_shed_total`, `http_responses_2xx_total`, and `db_pool_wait_count`. Gateway `/actuator/prometheus` stays 404 because that process has no admin authentication. Targets were not loosened.

## After: Cloud, 2026-09-28, repackaged services, 5 minutes
Gateway http://127.0.0.1:18090 after gateway, auth, user, audit, system, search, and RAG were replaced with the jars that contain the blacklist policy, pool shed, and request counters. Traffic and AI stayed on the jars built earlier the same day. Same profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/cloud-after-repackage-5m.log and artifacts/k6/cloud-after-repackage-5m.json.
requests=45558. http_req_failed_rate=0. checks_rate=1.000. avg=22.9ms. p95=63.1ms. p99=91.7ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Stderr was empty and every scenario finished. Targets were not loosened.
A second start written to the old cloud-after-static-discovery-5m name failed in setup because admin login was already rate limited, and it replaced that artifact. The failed files are artifacts/k6/cloud-static-discovery-failed-setup.log and artifacts/k6/cloud-static-discovery-failed-setup.json. They are not the 2026-09-27 acceptance run. The numbers for that earlier run remain in the section above.

## Static discovery packaged, 2026-09-28
Auth, user, audit, system, search, and RAG dev profiles now list the same static instances as traffic and AI. StaticDiscoveryConfigTest passed: 1 test, 0 failures. Those six modules were packaged and restarted without the extra config file, with Nacos disabled. The auth jar contains the user-service instance. Gateway login for ce@ce.com returned 200, and driver offense and fine reads returned 200. Targets were not loosened.

## Backup drill, 2026-09-28
The backup script was writing the dump through PowerShell text encoding, so the file started with a UTF-8 BOM and restore failed with a syntax error. mysqldump output is now copied as bytes. The file ACL is applied before `sys_backup_restore` is marked Success, so an ACL failure does not record Success. The earlier `traffic-20260928-141844.sql` row was marked Failed. `scripts/reliability/backup-traffic.ps1` then exited 0. Manifest artifacts/backups/traffic-20260928-142700.manifest.txt. git=713dbf9541346988f7800f12e430e874d704c2c0. binlog=FHNUM2-bin.000770 at 122592. Checksum: payment_record 13 rows, max 13, sum 809.00; fine_record 4, max 4, sum 800.00; deduction_record 0; appeal_record 1 row, max 1. `scripts/reliability/restore-traffic-scratch.ps1` exited 0 into `traffic_restore_drill`. The drill payment count and amount matched, 13 and 809.00. Live `traffic` stayed 13 rows and 809.00. fine 1 `paid_amount` stayed 202.00 in both databases. Targets were not loosened.

## Revoked token before missing ledger key, 2026-09-28
Quarkus checked a missing Idempotency-Key before authentication, so a logged-out token received 400 instead of 401. LedgerKeyFilter now runs after the JWT filter. LedgerKeyFilterOrderTest is in the tree. After live reload, admin logout on http://127.0.0.1:19080 returned 200, then GET /api/auth/me and POST /api/payments with the old token both returned 401.
Spring and Cloud traffic had the same order. Their guard filters now use order -90, after Spring Security's -100. Spring was restarted on 9080. Traffic was packaged and restarted on 18083. Admin logout then POST /api/payments returned 401 on both http://127.0.0.1:9080 and the gateway http://127.0.0.1:18090. A fresh driver token without the header still returned 400. payment_record stayed 13 rows and 809.00. fine 1 paid_amount stayed 202.00. Targets were not loosened.

## Debezium Connect, 2026-09-28
`scripts/dev-compose.yml` did not have a running Debezium container. `docker compose up -d debezium-connect` started `final-assignment-debezium-connect`. It is healthy on `127.0.0.1:8083`. `GET /connectors` returned 200 and `[]`. The connector was not registered. `scripts/debezium/register-mysql-cdc.sh` requires an existing CDC database user and password, and this round does not add database users or grants. Redpanda stayed healthy. Targets were not loosened.

## Go revoked token, 2026-09-28
On http://127.0.0.1:18080, admin logout returned 200 and the same token then got 401 from `POST /api/payments`. The missing-key check did not run first. No payment row was added.

## Bad request bodies are not 500, 2026-09-28
Spring `POST /actuator/ledgerReconcile` with a form body was an unhandled `HttpMediaTypeNotSupportedException` and returned 500. Cloud traffic turned a JSON parse error into 500 and included the parser text in the message. Both handlers now return 415 `UNSUPPORTED_MEDIA_TYPE` for an unsupported content type, and Cloud returns 400 `BAD_REQUEST` for an unreadable body without the parser text. Spring was restarted on 9080. Auth, user, traffic, audit, system, AI, search, and RAG were packaged and restarted with Nacos disabled. A form body to traffic reconcile returned 415, the body `x` with `application/json` returned 400, and `{}` returned 200. Gateway `ce@ce.com` `GET /api/offenses/driver/6` returned 200. Targets were not loosened.

## Spring my appeals page, 2026-09-28
`GET /api/appeals/my` defaulted `page` to 0. Appeal queries require page >= 1, so a driver call with no query returned 400 `INVALID_ARGUMENT`. Cloud, Quarkus, and Go already returned 200 for the same path. The default is now 1, matching the other list methods in that controller. Spring was restarted on 9080. `ce@ce.com` `GET /api/appeals/my` and `GET /api/appeals/my?page=1&size=10` both returned 200. Targets were not loosened.

## Redis down on the current processes, 2026-09-28
Local redis-server on 6379 was stopped after tokens had already been issued. Spring login returned 503 with Retry-After 1. `GET /api/payments?page=1&size=1` with the unrevoked token returned 200. `POST /api/payments` returned 503 with Retry-After 1. Cloud gateway login returned 503 with Retry-After 1, and the same unrevoked payment read returned 200. Quarkus and Go logins returned 503 with Retry-After 1. Redis was started again on 6379 and Spring login returned 200. payment_record stayed 13 rows and 809.00. fine 1 paid_amount stayed 202.00. Targets were not loosened.

## Redis down ledger writes, 2026-09-28
After the login probe, Redis on 6379 was stopped again with tokens already issued for Go, Quarkus, and the Cloud gateway. `GET /api/payments?page=1&size=1` returned 200 on all three. `POST /api/payments` returned 503 with Retry-After 1 on all three. No `sys_request_history` row was written for that probe key. Redis was started again and Go login returned 200. payment_record stayed 13 rows and 809.00. Targets were not loosened.
## Ollama down on the current processes, 2026-09-28
Windows Ollama and the Ubuntu Ollama service behind `127.0.0.1:11434` were both stopped. Nothing was listening on 11434. Both were started again afterward, and `GET http://127.0.0.1:11434/api/tags` returned 200. Targets were not loosened.

Spring `GET /api/ai/chat/actions?message=zzzz-reliability-probe&webSearch=false` on http://127.0.0.1:9080 returned 200 in 707ms with `isFallback=true`. During that call, 20 `GET /api/payments?page=1&size=1` requests returned 200.

Cloud AI on http://127.0.0.1:18086 returned 200 in 710ms with `isFallback=true`. The same call through the gateway http://127.0.0.1:18090 returned 200 in 711ms with `isFallback=true`. An earlier gateway sample of 1502ms used one shared client for the AI call and 20 ledger reads and is not the service time.

Go `GET /api/ai/chat/actions` returned 404. That route is not registered; the running model path is `POST /api/ai/chat/stream`. With Ollama down that stream returned 200 in 565ms, the body contained `isFallback=true`, and 10 concurrent payment reads returned 200. Action-list parity is not a gate.

Quarkus `GET /api/ai/chat/actions` does not call the model. `GET /api/ai/chat` is the model path. The first-token bound was 1 second, so the fallback arrived at 1054ms, outside the gate. The bound is now 700ms. After Quarkus reloaded, the same call returned 200 with `isFallback=true` in 18ms and again in 707ms. Payment reads during the 1054ms call were 10 of 10 status 200. A payment read after the 707ms call was 200 in 47ms.

payment_record stayed 13 rows and 809.00. fine 1 paid_amount stayed 202.00. No ledger POST was sent. Targets were not loosened.

## Kafka down on the current processes, 2026-09-28
Redpanda was stopped. Nothing was listening on 9092. It was started again afterward and reported healthy. The probe payments and their history rows were deleted after the checks. payment_record is 13 rows, max id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

Spring http://127.0.0.1:9080 returned 201 in 131ms. kafka_publish_failed_total moved from 0 to 1. History spring-k-20260928153149 was SUCCESS for payment 93576, status Pending.
Quarkus http://127.0.0.1:19080 returned 201 in 97ms. Its counter moved from 0 to 1. History quarku-k-20260928153149 was SUCCESS for payment 93578, status Pending.
Cloud gateway http://127.0.0.1:18090 returned 201 in 82ms. Traffic on 18083 moved kafka_publish_failed_total from 0 to 1. History cloud-k-20260928153149 was SUCCESS for payment 93579, status Pending.

Go http://127.0.0.1:18080 first returned 500 in 30ms. The history row was FAILED and no payment was inserted. The stored reason was duplicate entry '' for payment_record.uk_transaction_id. A missing transactionId was inserted as an empty string, while MySQL only allows one such value. CreatePayment now omits a blank transaction id so the column stays NULL. go test ./project/internal/service/payment passed. The rebuilt process is artifacts/go-backend-kafka-null.exe on 18080. With Redpanda stopped again, the same body without transactionId returned 201 in 12ms. kafka_publish_failed_total moved from 0 to 1. History go-k2-20260928154214 was SUCCESS for payment 93580, status Pending, transaction_id NULL.

## Elasticsearch down, current processes, 2026-09-28
final-assignment-elasticsearch was stopped. Nothing was listening on 9200. scripts/k6/ledger-read.js ran for 5 minutes at 16 VUs. Elasticsearch was started again afterward and reported healthy. Targets were not loosened.

Spring http://127.0.0.1:9080. Summary artifacts/k6/spring-es-down-current-5m.json and artifacts/k6/spring-es-down-current-5m.log.
requests=88278. http_req_failed=0. checks=88277/88277, rate 1.000. p95=8.01ms. p99=10.06ms. Exit 0.

Cloud gateway http://127.0.0.1:18090. Summary artifacts/k6/cloud-es-down-current-5m.json and artifacts/k6/cloud-es-down-current-5m.log.
requests=84251. http_req_failed=0.0005 (48 of 84251). checks=84202/84250, rate 0.9994. p95=20.2ms. p99=36.48ms. Exit 0.

## After: Go, 2026-09-28, blank transaction id, 5 minutes
Backend http://127.0.0.1:18080, binary artifacts/go-backend-kafka-null.exe. This replaces artifacts/go-backend-ledger-pool.exe. The change omits a blank transaction id on payment create. Profile: scripts/k6/full-api-load.js, 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. The summary text says backend=spring only because BACKEND was unset; BASE_URL was http://127.0.0.1:18080. Summary artifacts/k6/go-after-kafka-null-5m.log and artifacts/k6/go-after-kafka-null-5m.json. Stderr was empty.
requests=62143. http_req_failed_rate=0. checks_rate=1.000. avg=2.018ms. p95=3.371ms. p99=9.304ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.
Every k6 threshold in that script passed. payment_record stayed 13 rows, max id 13, sum 809.00. fine 1 paid_amount stayed 202.00. Targets were not loosened.

## Go model header timeout, 2026-09-28
The Go chat stream calls the OpenAI-compatible client. With the header timeout at 1 second, POST /api/ai/chat/stream returned 200 with isFallback true in 1021ms, outside the gate. Dial and response-header timeouts are now 700ms. TestModelResponseHeadersFailWithinOneSecond passed. The process on 18080 is artifacts/go-backend-ai-header.exe. The same stream then returned 200 with isFallback true in 852ms. A following payment read returned 200 in 3ms. The ledger code is unchanged from the 5 minute run on go-backend-kafka-null.exe. Targets were not loosened.

## Ledger reads during model fallback, 2026-09-28
Both Ollama servers were stopped and port 11434 was held open without a response, so the model call took the timeout path instead of failing on connection refused. Ollama was started again afterward and GET http://127.0.0.1:11434/api/tags returned 200. Targets were not loosened.

Spring http://127.0.0.1:9080, after five warmed payment reads: GET /api/ai/chat/actions returned 200 in 707ms with isFallback true. Six payment reads during that call were all 200. The slowest was 187ms, which is the p95 for a sample this small.
Cloud gateway http://127.0.0.1:18090, after the same warmup: the actions call returned 200 in 718ms with isFallback true. Nine payment reads were all 200. Sorted latencies put p95 at 116ms and the slowest at 116ms.
Quarkus http://127.0.0.1:19080: GET /api/ai/chat returned 200 in 740ms with isFallback true. Eighty payment reads were all 200, p95 3ms, max 37ms.
Go http://127.0.0.1:18080 on artifacts/go-backend-ai-header.exe: POST /api/ai/chat/stream returned 200 in 733ms with isFallback true. Eighty payment reads were all 200, p95 1ms, max 2ms.

## Overload shed on the current processes, 2026-09-28
scripts/k6/ledger-shed.js for 8 seconds. Go used artifacts/go-backend-ai-header.exe at 200 VUs. Spring and Cloud used 40 VUs. Quarkus used 200 VUs. Every run exited 0. Every 503 counted by the script had Retry-After 1. The replay check failed zero times, so a 201 was not followed by another 201 for the same key and body. Shed rows used payer name shed. They and their shed- history keys were deleted. payment_record is 13 rows, max id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. Targets were not loosened.

Go http://127.0.0.1:18080. Summary artifacts/k6/ledger-shed-go-ai-header.log. checks 21908/21908. shed_503=66.
Spring http://127.0.0.1:9080. Summary artifacts/k6/ledger-shed-spring-current.log. checks 18637/18652, rate 0.9991. shed_503=11705. Fifteen GET /api/auth/me responses were unexpected 5xx. Payment status checks and the replay check had no failures.
Cloud gateway http://127.0.0.1:18090. Summary artifacts/k6/ledger-shed-cloud-current.log. checks 30359/30472, rate 0.9962. shed_503=21729. One hundred eleven reads were unexpected 5xx. Two first payments were outside 201, 208, 400, 409, and 503 with Retry-After. The replay check had no failures.
Quarkus http://127.0.0.1:19080. Summary artifacts/k6/ledger-shed-quarkus-current.log. checks 152116/152116. shed_503=111666. No read or payment check failed.

## Driver gates on the current processes, 2026-09-28
ce@ce.com called the four current processes. GET /api/rag/admin/overview and GET /api/rag/admin/documents returned 403 on Spring 9080, Go 18080, Quarkus 19080, and the Cloud gateway 18090. GET /api/appeals/my and GET /api/appeals/my?page=1&size=10 returned 200 on all four.
Anonymous GET /actuator/health returned 200 and {"status":"UP"} on Go and Quarkus, and {"groups":["liveness","readiness"],"status":"UP"} on Spring and the gateway. None of those bodies included component details. Anonymous GET /actuator/prometheus returned 401 on Spring, Go, and Quarkus, and 404 on the gateway. Quarkus GET /q/health returned the same status-only body. A gateway login and a gateway payment read both echoed the caller X-Trace-Id. Targets were not loosened.

## After: Spring, Cloud, and Quarkus, 2026-09-28, current processes, 5 minutes
scripts/k6/full-api-load.js. Profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Stderr was empty for all three. payment_record stayed 13 rows, max id 13, sum 809.00. fine 1 paid_amount stayed 202.00. Targets were not loosened.

Spring http://127.0.0.1:9080, the process that has the appeals page default and the 415 body mapping. Summary artifacts/k6/full-api-spring-current-5m.log and artifacts/k6/full-api-spring-current-5m.json. Exit 0.
requests=48228. http_req_failed_rate=0. checks_rate=1.000. avg=18.926ms. p95=33.347ms. p99=87.437ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.

Cloud gateway http://127.0.0.1:18090, the current gateway and traffic processes. Summary artifacts/k6/full-api-cloud-current-5m.log and artifacts/k6/full-api-cloud-current-5m.json. Exit 0.
requests=46140. http_req_failed_rate=0. checks_rate=1.000. avg=21.855ms. p95=61.025ms. p99=99.218ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.

Quarkus http://127.0.0.1:19080, the current dev process. Summary artifacts/k6/full-api-quarkus-current-5m.log and artifacts/k6/full-api-quarkus-current-5m.json. Exit 0.
requests=49529. http_req_failed_rate=0. checks_rate=1.000. avg=15.522ms. p95=59.162ms. p99=97.419ms.
health_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000. login_ok=1.000.

## In-flight shed before the pool returns 500, 2026-09-28
A 40 VU overload let GET /api/auth/me pass the utilization sample and then fail as a 5xx without Retry-After. Spring and Cloud now also shed a non-ledger GET, and a ledger write, when requests in flight exceed the pool max. Ledger reads and health are not shed by that count. LedgerReliabilityPolicyTest and PoolShedPolicyTest passed.
Spring was restarted on 9080. The 8 second, 40 VU ledger-shed script then had checks 40256/40256 and shed_503=26643. The auth/me read check failed zero times. Summary artifacts/k6/ledger-shed-spring-inflight.log. Exit 0.
Cloud auth was repackaged and restarted on 8081. The same script through http://127.0.0.1:18090 had checks 57979/58064, rate 0.9985, and shed_503=41298. Payment and replay checks failed zero times. GET /api/auth/me still had 85 unexpected non-503 results. Summary artifacts/k6/ledger-shed-cloud-inflight.log. Exit 0.
Shed rows were deleted. payment_record is 13 rows, max id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. Targets were not loosened.

## Auth propagates a downstream shed, 2026-09-28
Under load, user service GET /api/users/internal/search/username/admin returned 503 LOAD_SHED. Auth treated that Feign failure as a missing user and threw IllegalStateException, so the gateway showed a generic 500 for GET /api/auth/me. A 503 or 504, or a Feign call with no HTTP status, now throws DependencyUnavailableException. Auth scans com.tutict.finalassignmentcloud.exception, so the handler returns 503 with Retry-After 1 and errorCode DEPENDENCY_TIMEOUT. LedgerConnectionSignalsTest passed: 3 tests, 0 failures. Auth was repackaged and restarted on 8081.
Forty concurrent callers for 8 seconds through http://127.0.0.1:18090 then saw 1730 responses of 200 and 78449 of 503. There were no 500s and no client failures. The 503 responses carried Retry-After 1. Targets were not loosened.

## Idempotent payment replay on the current processes, 2026-09-28
Each current process received one new payment key, the same key and body, then the same key with a different amount. Spring 9080, Go 18080, Quarkus 19080, and the Cloud gateway 18090 all returned 201, then 208, then 409. Four history rows were SUCCESS, and only four probe payments existed, so the replay did not insert a second row. The probe rows and history keys were deleted. payment_record is 13 rows and 809.00. fine 1 paid_amount is 202.00. Targets were not loosened.

## Failed retry and concurrent duplicate, 2026-09-28
A successful payment key was marked FAILED and its row deleted, then the same key and body was posted again. Spring 9080, Go 18080, Quarkus 19080, and the Cloud gateway 18090 all returned 201 again, and the history row was SUCCESS.
Two concurrent posts of one new key previously returned 201 and 208 on Spring, 201 and 409 on Go, but 201 and 500 on Quarkus and Cloud. The loser hit the idempotency unique key and the generic handler marked the shared history failed. A duplicate-key failure now returns 409 and does not mark that history failed. Quarkus includes Retry-After 1, matching its in-progress response. DuplicateKeySignalsTest passed on both. Traffic was repackaged and restarted on 18083. Quarkus dev reloaded. The same race then returned 201/409 on both. Two probe rows were deleted. payment_record is 13 rows and 809.00. fine 1 paid_amount is 202.00. Targets were not loosened.

## Full API after in-flight shed, 2026-09-28
scripts/k6/full-api-load.js, launched by artifacts/full-api-after-shed.ps1. Profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. These are the current processes after in-flight shedding and the duplicate-key 409 fix. Stderr was empty for all three, and all three exited 0. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

Spring http://127.0.0.1:9080, 17:23:09 to 17:28:33. Summary artifacts/k6/full-api-spring-after-shed-5m.log and artifacts/k6/full-api-spring-after-shed-5m.json.
requests=50172. http_req_failed=0/50172. checks=50475/50475. avg=15.392ms. p95=26.185ms. p99=47.185ms.
health_ok=1.000. login_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000.

Cloud gateway http://127.0.0.1:18090, 17:28:33 to 17:33:58. Summary artifacts/k6/full-api-cloud-after-shed-5m.log and artifacts/k6/full-api-cloud-after-shed-5m.json.
requests=45217. http_req_failed=3/45217, rate 0.000066. checks=45517/45520, rate 0.999934. avg=24.086ms. p95=63.499ms. p99=160.234ms.
health_ok=1.000. login_ok=1.000. user_read_ok=1.000. super_read_ok=1.000. admin_read_ok=5245/5248, rate 0.999428. The three misses were `admin_me status is 2xx` twice and `admin_vehicles status is 2xx` once. The response status was not in the k6 log. Both rates are inside the contract. The target was not loosened.

Quarkus http://127.0.0.1:19080, 17:33:58 to 17:39:21. Summary artifacts/k6/full-api-quarkus-after-shed-5m.log and artifacts/k6/full-api-quarkus-after-shed-5m.json.
requests=51319. http_req_failed=0/51319. checks=51621/51621. avg=12.823ms. p95=46.262ms. p99=83.604ms.
health_ok=1.000. login_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000.

## Docker Desktop inference socket, 2026-09-28
Docker Desktop 4.47.0 raised its fatal dialog: Inference manager could not remove the unix listener `C:\Users\tutic\AppData\Local\Docker\run\dockerInference`. That path is a reparse point, and fsutil returns Windows error 1920, so it cannot be deleted in place. EnableDockerAI and EnableInference were already false. The engine did not exit. Redpanda, Elasticsearch, and Debezium Connect stayed healthy. `final-assignment-redis` and Nacos stayed stopped. The engine was not restarted and Docker was not factory reset. Older `run.broken-*` directories are previous renames of this same socket; renaming is only safe after Docker has stopped, and the next start creates the socket again.

## Cloud overload after auth shed propagation, 2026-09-28
scripts/k6/ledger-shed.js through the current gateway http://127.0.0.1:18090. Profile: 40 VUs, 8 seconds. Auth on 8081 is the process that maps a downstream 503 to 503 with Retry-After 1. Summary artifacts/k6/ledger-shed-cloud-auth-propagate.log and artifacts/k6/ledger-shed-cloud-auth-propagate.json. Stderr was empty. Exit 0.
checks=94884/94884. shed_503=69362. Every named check passed, including `read is not an unexpected 5xx`, `first payment is accepted, shed, or a client conflict`, and `replay does not create another payment`. k6 http_req_failed was 69362/71164 because it counts the intentional 503 responses; those responses carried Retry-After 1 and are not contract failures.
The run inserted 841 Pending payment rows for payer name shed, ids 105346 through 106186, and 841 SUCCESS history rows. Those rows were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. Targets were not loosened.

## Stale PROCESSING reconcile on the current processes, 2026-09-28
Each probe inserted three history rows and then called POST /actuator/ledgerReconcile. `recon-*-miss` was PROCESSING, three minutes old, with no business id. `recon-*-hit` was PROCESSING, three minutes old, and pointed at payment_id 13. `recon-*-fresh` was PROCESSING with updated_at of now. No other PROCESSING row was older than two minutes before the probes. The probe rows were deleted afterward. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

Go http://127.0.0.1:18080 returned 200 with updated 2. The missing row became FAILED, payment 13 became SUCCESS, and the fresh row stayed PROCESSING.
Quarkus http://127.0.0.1:19080 did the same.
Cloud traffic http://127.0.0.1:18083, using an admin token from the gateway, did the same.

Spring http://127.0.0.1:9080 first returned 500 INTERNAL_ERROR and left all three rows PROCESSING. The row mapper cast ResultSet.getObject of the unsigned business_id to Long, which the MySQL driver does not return as Long. It now uses getLong and wasNull, the same read Cloud already used. LedgerReconciliationRowTest passed: 2 tests, 0 failures. Spring was restarted with artifacts/start-spring-normal.ps1. The new process listens on 9080 and 8080. The same probe then returned 200 with updated 2, FAILED, SUCCESS, and the fresh row still PROCESSING.

## Backup timestamp follows a new success row, 2026-09-28
Spring and Cloud traffic previously set `backup_last_success_timestamp` only on startup. Go and Quarkus already queried `sys_backup_restore` on each Prometheus scrape. Both startup gauges now install a reader that runs that query when the gauge is scraped. A failed read keeps the previous value. `UNIX_TIMESTAMP` is read as a Number, so an unsigned result is not cast to Long. BackupTimestampGaugeTest passed on Spring: 3 tests, 0 failures. The same test plus TrafficReliabilityMetricsTest passed on Cloud traffic: 5 tests, 0 failures.
Spring was restarted with artifacts/start-spring-normal.ps1 and listens on 9080 and 8080. Cloud traffic was repackaged and restarted on 18083 with Nacos disabled. A probe Success row named probe-gauge-20260928 had UNIX_TIMESTAMP 1790589953. The next scrape moved all four gauges from 1790576821 to 1790589953. The probe row was deleted. The following scrape returned all four gauges to 1790576821. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

## Unknown history type does not abort reconcile, 2026-09-28
A stale PROCESSING row with a business id and a business type that is not payment, fine, deduction, or appeal used to make Spring and Cloud reconciliation throw before any row was updated. The column lookup now returns no table for an unknown type, and that row is FAILED. Go and Quarkus already did this. LedgerReconciliationTableTest passed on Spring and on Cloud traffic: 2 tests each, 0 failures.
Each current process received three history rows: NOTE with business id 13 and age three minutes, PAYMENT_CREATE with no business id and age three minutes, and a fresh PROCESSING row. Go http://127.0.0.1:18080, Quarkus http://127.0.0.1:19080, Spring http://127.0.0.1:9080, and Cloud traffic http://127.0.0.1:18083 each returned 200 with updated 2. The unknown row and the missing payment became FAILED. The fresh row stayed PROCESSING. Spring was restarted with artifacts/start-spring-normal.ps1. Cloud traffic was repackaged and restarted on 18083 with Nacos disabled. Probe rows were deleted. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

## Gateway trace id and Redis health, 2026-09-28
The gateway was adding its own `X-Trace-Id` and also copying the downstream header, so one caller id came back twice. The response header filter now keeps that one id. TraceIdGlobalFilterTest passed: 1 test, 0 failures. After the gateway was repackaged and restarted on 18090 with Nacos disabled, anonymous `GET /api/payments/not-a-number` with `X-Trace-Id: probe-trace-abc123` returned 401 and a single `X-Trace-Id` header.
The same restart first reported aggregate `/actuator/health` DOWN. Readiness and liveness were UP. The Redis 5 INFO parser cannot read this server, and the gateway still had the Redis health indicator enabled. It is now off unless `MANAGEMENT_HEALTH_REDIS_ENABLED` is set, matching the other local-dev services. GatewayRouteContractTest passed: 1 test, 0 failures. Anonymous `GET /actuator/health` then returned 200 and `{"groups":["liveness","readiness"],"status":"UP"}`. No component details were included. Targets were not loosened.

## Same trace id in gateway and traffic logs, 2026-09-28
Gateway and traffic logs previously showed an empty traceId during a request, so an incident could not be lined up from the two processes. A response of 400 or more now writes one info line while the trace id is in the logging context. Successful responses are not logged. TraceIdGlobalFilterTest and GatewayRouteContractTest passed: 2 tests, 0 failures. The gateway and traffic jars were repackaged and restarted on 18090 and 18083 with Nacos disabled.
Anonymous `GET /api/payments/not-a-number` through http://127.0.0.1:18090 with `X-Trace-Id: probe-trace-log-20260928` returned 401 and one response header. The gateway log and the traffic log both contain that id for `GET /api/payments/not-a-number -> 401`. Anonymous `GET /actuator/health` on the gateway returned 200 and status UP. Targets were not loosened.

## Fine and appeal decision idempotency, 2026-09-28
Cloud fine, deduction, appeal create, and appeal review previously marked `sys_request_history` SUCCESS before the ledger row existed, and a second post with the same key threw a generic duplicate error. Those four reserves now use HistoryReserve: the history row stays PROCESSING until the ledger insert commits, the stored fingerprint is kept, the same fingerprint replays, and a different fingerprint conflicts. Kafka publish after the insert does not fail the request. HistoryReserveTest passed: 3 tests, 0 failures. Traffic was repackaged and restarted on 18083 with Nacos disabled.
Through http://127.0.0.1:18090, a fine POST without Idempotency-Key returned 400. Key probe-fine-20260928 then returned 201, 208, and 409. One fine row was inserted, amount 1.00, and its history was SUCCESS with a sha256 fingerprint. The probe fine and history were deleted. fine_record is 4 rows, max fine_id 4.
Appeal 1 review key probe-review-20260928 returned 201, 208, and 409. One review row was inserted, level Primary, and its history was SUCCESS with a sha256 fingerprint. The probe review and history were deleted. appeal_review is 0 rows. appeal_record stayed 1 row. payment_record stayed 13 rows and 809.00. Targets were not loosened.

## Quarkus fine and appeal decision idempotency, 2026-09-28
Quarkus fine, deduction, appeal create, and appeal review still marked history SUCCESS before the ledger row existed, and a repeated key became a generic duplicate error. They now use HistoryReserve: PROCESSING until the insert commits, the sha256 fingerprint is kept, the same fingerprint returns 208, and a different fingerprint returns 409. The dev process on http://127.0.0.1:19080 reloaded the change.
A fine POST without Idempotency-Key returned 400. Key probe-q-fine-20260928 returned 201, 208, and 409. One fine row was inserted with amount 1.00, and its history was SUCCESS with a sha256 fingerprint. Appeal 1 review key probe-q-review-20260928 returned 201, 208, and 409. One Primary review was inserted, and its history was SUCCESS with a sha256 fingerprint. Both probe rows and history keys were deleted. fine_record is 4 rows, max fine_id 4. appeal_review is 0 rows. appeal_record stayed 1 row. payment_record stayed 13 rows and 809.00. Targets were not loosened.

## Go fine idempotency on the current process, 2026-09-28
Go fine create already reserves `sys_request_history` as PROCESSING and finishes SUCCESS only after the insert. The current process is artifacts/go-backend-ai-header.exe on http://127.0.0.1:18080. A fine POST without Idempotency-Key returned 400. Key probe-go-fine-20260928 returned 201, then 208, then 409 IDEMPOTENCY_CONFLICT for a different amount. One fine row was inserted, fine_id 7, amount 1.00. Its history was SUCCESS, business_id 7, with a sha256 fingerprint. The probe fine and history were deleted. fine_record is 4 rows, max fine_id 4. payment_record stayed 13 rows and 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00.
The create call now inserts the row before reading the generated id into Finish. Deduction create and appeal create use that same order. Appeal review already did. The running binary was not replaced. Targets were not loosened.

## Go deduction scoring cycle, 2026-09-28
Go deduction create built a default scoring cycle of `2026-01-01至2027-01-01`. That is 21 characters, and `deduction_record.scoring_cycle` is `varchar(20)`, so the insert failed with MySQL 1406 and the history row was FAILED. The default is now `2026-2027`. TestDefaultScoringCycleFitsColumn passed. Fine, deduction, and appeal create also insert the row before reading the generated id into the history finish call.
The process on http://127.0.0.1:18080 is now artifacts/go-backend-deduction.exe, started with Nacos unused, Redis on localhost:6379, and TOKEN_BLACKLIST_FAIL_OPEN=false. Key probe-go-deduct-20260928c returned 201, 208, and 409. One deduction row was inserted, 1 point, scoring cycle 2026-2027. Its history was SUCCESS with business_id 1 and a sha256 fingerprint. The probe row and the earlier FAILED history keys were deleted. deduction_record is 0 rows. fine_record stayed 4 rows. payment_record stayed 13 rows and 809.00. Targets were not loosened.

## Go appeal decision idempotency, 2026-09-28
Go appeal review create already reserves history as PROCESSING and returns 208 or 409 from that row. A body without suggestedAction failed before the decision row existed: the empty string was written into the enum column and MySQL returned 1265. An empty suggested action is now omitted, so the column stays NULL. The process on http://127.0.0.1:18080 is artifacts/go-backend-review.exe.
Key probe-go-review-20260928f, with no suggestedAction, returned 201, 208, and 409. One review row was inserted, level Primary, suggested_action NULL. Its history was SUCCESS, business_id 4, with a sha256 fingerprint. The probe review and history keys were deleted. appeal_review is 0 rows. appeal_record stayed 1 row. fine_record stayed 4 rows. deduction_record stayed 0 rows. payment_record stayed 13 rows and 809.00. Targets were not loosened.

## Spring fine, appeal decision, and optimistic lock, 2026-09-28
The current Spring process on http://127.0.0.1:9080 already keeps fine and appeal-review history PROCESSING until the row commits. A fine POST without Idempotency-Key returned 400. Key probe-spring-fine-20260928 returned 201, 208, and 409. Appeal 1 review key probe-spring-review-20260928, with no suggestedAction, returned 201, 208, and 409.
A probe payment was created at version 0. PUT /api/payments/106187 with version 0 returned 200 and moved the row to version 1. The same body and stale version 0 with a new key returned 409 CONFLICT, message `Payment record was updated concurrently; refresh and retry`. The probe payment, fine, review, and history keys were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine_record is 4 rows. appeal_review is 0 rows. appeal_record stayed 1 row. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

## Deduction create defaults, 2026-09-28
Cloud, Quarkus, and Spring deduction create defaulted a blank status to Pending, which is not in the status enum, and they left scoring_cycle and handler empty. scoring_cycle and handler are NOT NULL and have no database default, so the insert failed. A blank status is now Effective. A blank scoring cycle is the four-digit year, a hyphen, and the next year, which fits varchar(20). A blank handler is system.
Cloud traffic was repackaged and restarted on 18083. Spring was restarted on 9080. Quarkus dev on 19080 reloaded. Each received one key and a body with only offenseId, driverId, and deductedPoints. Cloud, Quarkus, and Spring returned 201, 208, and 409. Three deduction rows were inserted, all Effective, handler system, scoring cycle 2026-2027, 1 point. Their history rows were SUCCESS with sha256 fingerprints. The rows and probe history keys were deleted. deduction_record is 0 rows. fine_record stayed 4 rows. payment_record stayed 13 rows and 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

## Appeal create defaults, 2026-09-28
Appeal create has required columns with no database default: appeal number, appellant name, appellant id card, appeal type, reason, and time. evidence_urls is JSON and rejects an empty string. Spring already returned 400 for a missing name, id card, contact, reason, or time, and 201, 208, 409 for a complete body. Cloud and Quarkus did not fill appeal number, type, acceptance, process status, or time, so the insert failed. Go wrote an empty evidence_urls string and MySQL returned 3140. Cloud and Quarkus now fill those defaults in validation, and a blank evidence URL stays null. Go omits a blank evidence URL.
Cloud traffic was repackaged and restarted on 18083. Go is artifacts/go-backend-appeal.exe on 18080. Quarkus dev on 19080 reloaded. With a complete body, Cloud, Go, and Quarkus each returned 201, 208, and 409. Probe appeals named probe-appeal and their history keys were deleted. appeal_record is the original row, appellant Smoke User. appeal_review is 0 rows. fine_record stayed 4 rows. payment_record stayed 13 rows and 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

## Docker Desktop inference socket again, 2026-09-28
The same Docker Desktop 4.47.0 dialog appeared again: Inference manager could not remove `C:\Users\tutic\AppData\Local\Docker\run\dockerInference`. The path is still a reparse point and fsutil still returns Windows error 1920. EnableDockerAI and EnableInference were already false. The engine had not exited. Redpanda, Elasticsearch, and Debezium Connect were healthy. `final-assignment-redis` and Nacos stayed stopped. The engine was not restarted, the `run` directory was not renamed while the engine was up, and Docker was not factory reset.

## Payment optimistic lock on Cloud, Go, and Quarkus, 2026-09-28
Spring already returned 409 for a stale payment version. Cloud's mapped payment entity had no version column, and its MyBatis session had no optimistic-lock interceptor, so a stale version was written. Quarkus produced an optimistic-lock interceptor but never installed it, and its payment entity had no version field. Go checked `version` only when it was greater than zero, so the initial version 0 matched every update. A blank Go transaction id was also written as an empty string and hit `uk_transaction_id` before the version check.

Cloud now maps `version` and registers MyBatis-Plus `OptimisticLockerInnerInterceptor`. A zero-row update of an existing payment is 409. Quarkus maps `version` and updates with `WHERE payment_id = ? AND version = ?`, then sets version to the previous value plus one. Go always includes version 0 in that predicate and leaves a blank transaction id unset. The current processes are Cloud traffic on 18083, Go `artifacts/go-backend-lock2.exe` on 18080, and the Quarkus dev process on 19080.

Each probe used a new payment for fine 1, driver 28, amount 1.00, payer name probe-lock. The first PUT sent version 0. The second PUT sent the same stale version 0 with a different idempotency key.

Cloud through http://127.0.0.1:18090 created payment 106188 at version 0, returned 200 and moved it to version 1, then returned 409 while version stayed 1.
Quarkus http://127.0.0.1:19080 created payment 106189 at version 0, returned 200 and version 1, then 409 with version still 1.
Go http://127.0.0.1:18080 created payment 106191 at version 0, returned 200 and version 1, then 409 `PAYMENT_CONFLICT` with message `payment record was updated concurrently`. Version stayed 1.

The probe payments and `probe-lock-%` history rows were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine_record is 4 rows. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. appeal_record is 1 row. appeal_review is 0 rows. deduction_record is 0 rows. Targets were not loosened.

## Go omitted payment version, 2026-09-28
The first Go optimistic-lock build treated a missing JSON version as 0. The Flutter payment model does not send version, so the second save of an unchanged payment would become 409. Version is now a pointer. A missing version does not add a version predicate and does not change the column, matching MyBatis-Plus when the value is null. An explicit version, including 0, still requires that row version and then increments it. GORM replaces the omit list on each call, so create now omits a blank transaction id and a missing version in one call. An update that changes no column returns 200 when no version was sent, instead of a false conflict. The process is artifacts/go-backend-lock5.exe on http://127.0.0.1:18080.

Payment probe-lock-go-nil was created without version at version 0. Two PUTs without version returned 200 and left version 0. A PUT with version 0 returned 200 and moved the row to version 1. Another PUT without version returned 200 and left version 1. A PUT with stale version 0 returned 409 PAYMENT_CONFLICT, message `payment record was updated concurrently`, and version stayed 1. The probe payment and probe-lock history rows were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. Targets were not loosened.

## Quarkus logout then payment, current process, 2026-09-28
The Quarkus dev process on http://127.0.0.1:19080 is the one that reloaded payment optimistic locking. ce@ce.com logged in, logged out, and GET /api/auth/me with the old token returned 401, body `Token has expired, please login again`. The same account is not allowed to create payments, so POST /api/payments with that token is 403 even before logout. admin logged in, logged out, and POST /api/payments with the old token and a new idempotency key returned 401 with the same expired-token body. No payment row was inserted. Targets were not loosened.

## After: current binaries, 2026-09-28, 5 minutes
scripts/k6/full-api-load.js through artifacts/full-api-lock5.ps1. Profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. These are the processes after payment optimistic locking and the Go omitted-version fix. Login 429 is an expected login response in the script, so it is shedding, not an http_req_failed. Stderr was empty for every run. All four exited 0. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

Go http://127.0.0.1:18080, binary artifacts/go-backend-lock5.exe, 19:57:47 to 20:03:11. Summary artifacts/k6/full-api-go-lock5-5m.log and artifacts/k6/full-api-go-lock5-5m.json.
requests=61482. http_req_failed_rate=0. checks_rate=1.000. p95=3.842ms. p99=9.616ms.
health_ok=1.000. login_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000.

Spring http://127.0.0.1:9080, 20:03:11 to 20:08:35. Summary artifacts/k6/full-api-spring-lock5-5m.log and artifacts/k6/full-api-spring-lock5-5m.json.
requests=46694. http_req_failed_rate=0. checks_rate=1.000. p95=37.183ms. p99=59.669ms.
health_ok=1.000. login_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000.

Cloud gateway http://127.0.0.1:18090, traffic pid 36312, 20:08:35 to 20:13:59. Summary artifacts/k6/full-api-cloud-lock5-5m.log and artifacts/k6/full-api-cloud-lock5-5m.json.
requests=43834. http_req_failed_rate=0. checks_rate=1.000. p95=74.215ms. p99=185.043ms.
health_ok=1.000. login_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000.

Quarkus http://127.0.0.1:19080, 20:13:59 to 20:19:24. Summary artifacts/k6/full-api-quarkus-lock5-5m.log and artifacts/k6/full-api-quarkus-lock5-5m.json.
requests=44151. http_req_failed_rate=0. checks_rate=1.000. p95=93.300ms. p99=136.998ms.
health_ok=1.000. login_ok=1.000. user_read_ok=1.000. admin_read_ok=1.000. super_read_ok=1.000.

## Go overload on the current binary, 2026-09-28
scripts/k6/ledger-shed.js against artifacts/go-backend-lock5.exe at http://127.0.0.1:18080. The pool max is 50. At 40 VUs for 8 seconds every request stayed inside the pool, so shed_503 was 0 and the script threshold exited non-zero. Checks were 18184/18184, including replay does not create another payment. That run inserted 4546 shed payments. They were deleted before the next run. payment_record was back to 13 rows and 809.00.

At 200 VUs for 8 seconds the same binary returned shed_503=726. checks=22256/22256. Every named check passed: read is not an unexpected 5xx, first payment is accepted, shed, or a client conflict, replay does not create another payment, and a 503 carries Retry-After 1. k6 http_req_failed was 726/16693 because it counts those intentional 503 responses. Summary artifacts/k6/ledger-shed-go-lock5-200.log and artifacts/k6/ledger-shed-go-lock5-200.json. Stderr was empty. Exit 0.
The run inserted 5497 shed payments, amount 1.00 each. Those rows and the shed-% history keys were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine_record is 4 rows. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. appeal_record is 1 row. appeal_review is 0 rows. deduction_record is 0 rows. Targets were not loosened.

## Cloud Elasticsearch timeout fallback, 2026-09-28
Cloud already had an Elasticsearch repository guard, but it treated only connection refused and a few exception names as unavailable. A socket timeout or a Spring Data Elasticsearch exception still escaped. A payment write then failed after MySQL commit, and a ledger read did not reach the MySQL fallback. Timeouts, connect failures, and Elasticsearch client exceptions now use the same fallback. The first failure opens a 15 second circuit so later reads do not each wait out the timeout. ElasticsearchUnavailableGuardTest passed: 2 tests, 0 failures. Traffic was repackaged and restarted on 18083. Nacos stayed disabled.

final-assignment-elasticsearch was stopped. Through http://127.0.0.1:18090, admin GET /api/payments?page=1&size=1 returned 200 in 635ms, and POST /api/payments returned 201 in 104ms. The probe payment was deleted. Three more list reads, while the circuit was open and Elasticsearch was still stopped, returned 200 in 29ms, 20ms, and 18ms. Elasticsearch was started again and became healthy. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. Targets were not loosened.

## Kafka down on the current processes, 2026-09-28
final-assignment-redpanda was stopped. Each current process received one payment create. All four returned 201 before the producer gave up. Go took 33ms, Quarkus 70ms, Spring 199ms, and Cloud through http://127.0.0.1:18090 took 259ms. Before the stop, kafka_publish_failed_total was 0 on Go, Spring, Quarkus, and Cloud traffic. After the async publish failed it was 1 on each. The probe payments and probe-kafka history rows were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. Redpanda was started again and is healthy. Elasticsearch and Debezium Connect stayed healthy. Targets were not loosened.

## After: Cloud, 2026-09-28, Elasticsearch circuit, 5 minutes
The previous Cloud 5 minute run used traffic pid 36312. Traffic was then repackaged with the Elasticsearch timeout fallback and circuit and restarted as pid 40684 at 20:41:32. Gateway stayed on 18090. scripts/k6/full-api-load.js, 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/full-api-cloud-es-circuit-5m.log and artifacts/k6/full-api-cloud-es-circuit-5m.json. Stderr was empty. Exit 0.
requests=45958. http_req_failed=4/45958, rate 0.000087. checks=46256/46260, rate 0.999914. p95=62.390ms. p99=107.934ms.
health_ok=5960/5960. login_ok=300/300. user_read_ok=31895/31896, rate 0.999969. admin_read_ok=5451/5454, rate 0.999450. super_read_ok=2344/2344.
The four misses were not identified in the summary. All rates stay inside the contract. The target was not loosened. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00.

## Redis down, Go redial, 2026-09-28
go-redis v9.22.0 turns MaxRetries -1 into 0, so a dead pooled connection is not retried. lock5 could stay on that connection and keep returning 503 after Redis was back. Both Go clients now set MaxRetries to 1, and the dial timeout stays 200ms. TestRedisCommandTimeouts passed. The process is artifacts/go-backend-lock6.exe, pid 44500, on http://127.0.0.1:18080. It replaced lock5. Local redis-server answered PONG, was stopped, then started again as pid 45680 and answered PONG. final-assignment-redis stayed stopped. Tokens were not written here.

Before the stop, admin login was 200: Go 236ms, Spring 271ms, Cloud gateway 204ms, Quarkus 296ms. With those tokens, after 6379 stopped listening:

Go GET /api/payments?page=1&size=1 returned 200 in 405ms. GET /api/auth/me returned 200 in 407ms. POST /api/payments returned 503 in 407ms, Retry-After 1, errorCode DEPENDENCY_TIMEOUT.
Spring returned 200 in 534ms, 200 in 220ms, and 503 in 204ms with Retry-After 1. The post body said the revocation store is unavailable.
Cloud through http://127.0.0.1:18090 returned 200 in 214ms, 200 in 833ms, and 503 in 204ms with Retry-After 1 and DEPENDENCY_TIMEOUT.
Quarkus returned 200 in 43ms, 200 in 10ms, and 503 in 14ms with Retry-After 1 and DEPENDENCY_TIMEOUT.

After Redis answered PONG again, admin login was 200 on Go in 168ms, Spring in 228ms, Cloud in 210ms, and Quarkus in 229ms. The Go login is the redial check for the connection opened before the stop. No payment row was inserted. payer_name probe-redis and idempotency_key probe-redis-% were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. fine_record is 4 rows. appeal_record is 1 row. appeal_review is 0 rows. deduction_record is 0 rows. Probe rows are 0. Targets were not loosened.

## Docker Desktop inference socket, engine still up, 2026-09-28
The same dialog appeared again: Inference manager could not remove C:\Users\tutic\AppData\Local\Docker\run\dockerInference. The path is still a reparse point and fsutil still returns Windows error 1920. EnableDockerAI and EnableInference are false. The engine had not exited. docker info reported ServerVersion 28.4.0. Redpanda, Elasticsearch, and Debezium Connect were healthy. final-assignment-redis and Nacos stayed stopped. The engine was not restarted, the run directory was not renamed while the engine was up, and Docker was not factory reset.

## After: Go lock6, 2026-09-28, 5 minutes
scripts/k6/full-api-load.js against artifacts/go-backend-lock6.exe at http://127.0.0.1:18080. Profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. This is the process after Redis MaxRetries changed from -1 to 1. Summary artifacts/k6/full-api-go-lock6-5m.log and artifacts/k6/full-api-go-lock6-5m.json. Stderr was empty. The run finished with 0 interrupted iterations. Thresholds in the summary were all ok.
requests=61791. http_req_failed=0/61791, rate 0. checks=62094/62094, rate 1. p95=3.347ms. p99=5.298ms. max=205.927ms.
health_ok=5964/5964. login_ok=301/301. user_read_ok=47448/47448. admin_read_ok=5708/5708. super_read_ok=2366/2366.
payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. fine_record stayed 4 rows. appeal_record stayed 1 row. appeal_review stayed 0. deduction_record stayed 0. Targets were not loosened.

## Cloud ledger read with Elasticsearch down, current traffic, 2026-09-28
final-assignment-elasticsearch was stopped. 127.0.0.1:9200 refused connections. The current traffic process stayed on 18083 and the gateway on 18090. scripts/k6/ledger-read.js ran for 5 minutes at 16 VUs through the gateway: payments, fines, deductions, appeals, and offenses. Summary artifacts/k6/cloud-es-down-circuit-5m.log. No JSON summary was written because that script does not export one. Stderr was empty. Exit followed the passed thresholds.
requests=88320, including the setup login. checks=88319/88319, rate 1. http_req_failed=0/88320. p95=6.33ms. p99=8.21ms. max=190.03ms. 0 interrupted iterations.
Elasticsearch was started again and became healthy. Redpanda and Debezium Connect stayed up. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. fine_record stayed 4 rows. appeal_record stayed 1 row. appeal_review stayed 0. deduction_record stayed 0. Targets were not loosened.

## Current process contract probe, 2026-09-28
The four current processes were checked without loosening targets. Admin login was 200 on each. A payment POST without Idempotency-Key returned 400 MISSING_HEADER: Go 4ms, Spring 4ms, Cloud gateway 3ms, Quarkus 1ms. The same missing-key POST returned 400 for fines, deductions, appeals, appeal 1 reviews, and POST /api/workflow/payments/1/events/PAY. GET /api/payments echoed the sent X-Trace-Id trace-probe-nokey on all four. ce@ce.com received 403 from GET /api/rag/admin/overview and 200 from GET /api/appeals/my on all four. Quarkus admin logout returned 200. The old token then got 401 on GET /api/auth/me and POST /api/payments. No payment or history row was inserted. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00.

## Idempotency on the current processes, 2026-09-28
Each current process got one new payment key, the same body again, and then the same key with amount 2.00. Go, Spring, Cloud through http://127.0.0.1:18090, and Quarkus all returned 201, then 208, then 409 IDEMPOTENCY_CONFLICT. Each key inserted one row. The replay and the conflict did not add a second row or change the amount. A FAILED sys_request_history row for a new key was then retried. All four returned 201, inserted one payment, and moved that history row to SUCCESS. Two concurrent posts of one key inserted one row: Go 201 and 409, Spring 201 and 208, Cloud 201 and 409, Quarkus 201 and 409. The probe payments and probe-idem, probe-fail, and probe-conc history rows were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. fine_record is 4 rows. appeal_record is 1 row. appeal_review is 0. deduction_record is 0. Targets were not loosened.

## Ollama down on the current processes, 2026-09-28
The Windows Ollama app and the Ubuntu ollama.service were both stopped. 127.0.0.1:11434 then refused connections. Elasticsearch stayed healthy. Both Ollama processes were started again afterward, and GET http://127.0.0.1:11434/api/tags returned 200. Targets were not loosened.

While the port was refused, admin calls returned 200 with isFallback true: Spring GET /api/ai/chat/actions in 50ms, Cloud AI on 18086 in 713ms, the same call through gateway 18090 in 709ms, Go POST /api/ai/chat/stream in 428ms, and Quarkus GET /api/ai/chat in 24ms with reason model_unavailable. A payment read immediately after each fallback returned 200, from 2ms to 20ms. Those reads did not overlap the model wait. The 5 minute Spring run below did overlap the outage.

scripts/k6/ledger-read.js then ran for 5 minutes at 16 VUs against Spring http://127.0.0.1:9080 while Ollama was still down. Summary artifacts/k6/spring-ollama-down-ledger-5m.log. Stderr was empty. 0 interrupted iterations.
requests=88183, including the setup login. checks=88182/88182. http_req_failed=0/88183. p95=7.85ms. p99=9.83ms. max=240.91ms.
payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00.

## Login limit ignores forwarded headers, current processes, 2026-09-28
A nonexistent account, rate-probe-not-a-user, posted a wrong password nine times to each current process. Every request also sent X-Forwarded-For 203.0.113.50 and X-Real-IP 203.0.113.51. Attempts 1 through 8 were 401. Attempt 9 was 429 with Retry-After 120 on Go 18080, Spring 9080, the Cloud gateway 18090, and Quarkus 19080. An admin login with the same forwarded headers then returned 200 on all four, so the spoofed address did not lock the real client or the admin account. Targets were not loosened.

## Backup drill, current script, 2026-09-28
scripts/reliability/backup-traffic.ps1 exited 0. The first attempt inside the sandbox created traffic-20260928-215245.sql and stopped at icacls with access denied, so sys_backup_restore did not record Success. Those partial files were deleted. The unrestricted rerun wrote artifacts/backups/traffic-20260928-215316.sql, its checksum, and its manifest. The manifest has the git HEAD and binlog FHNUM2-bin.000770 at 62537870. Checksum: payment_record 13 rows, max 13, sum 809.00; fine_record 4, max 4, sum 800.00; deduction_record 0; appeal_record 1 row, max 1. The dump ACL is only FHNUM2\tutic:(R,W). Success was recorded after that ACL was applied.
scripts/reliability/restore-traffic-scratch.ps1 exited 0 into traffic_restore_drill. The drill matched the checksum, including payment 13 rows and 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00 in both databases. Live traffic stayed 13 rows, max payment_id 13, sum 809.00. fine_record stayed 4. appeal_record stayed 1. appeal_review stayed 0. deduction_record stayed 0. Targets were not loosened.

## Prometheus on the current processes, 2026-09-28
Admin scrapes returned 200 and included load_shed_total, idempotency_conflict_total, dependency_timeout_total, ai_fallback_total, backup_last_success_timestamp, a db_pool wait gauge, and http_responses_2xx_total. Go /actuator/prometheus, Spring 9080, Quarkus /actuator/prometheus, and Quarkus /q/metrics all did. backup_last_success_timestamp was 1790603596, which is 2026-09-28 21:53:16, the Success row written by traffic-20260928-215316.sql. Cloud traffic on 18083 returned the ledger counters, db_pool_wait_count, kafka_publish_failed_total, and the same backup gauge. It does not emit ai_fallback_total. Cloud AI on 18086 does, and that scrape showed ai_fallback_total 10. Anonymous scrapes were already 401, and the gateway still does not expose Prometheus. Targets were not loosened.

## Optimistic lock on the current processes, 2026-09-28
A new key was created, then the same key with version 9999 was sent as a stale update. The response was 409 on Go, Spring, Cloud, and Quarkus. The version in the live row was 0. The probe payments and probe-lock history rows were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. fine_record is 4 rows. appeal_record is 1 row. appeal_review is 0. deduction_record is 0. Targets were not loosened.
POST /api/workflow/appeals/1/events/APPROVE without Idempotency-Key returned 400 on those same four processes. No appeal or history row was written.

## Max execution time and connection acquisition timeout on the current processes, 2026-09-28
Online SQL is capped at 3 seconds. Go ledger borrows are capped at 200ms. Spring and Cloud Hikari stay at the 250ms driver floor, and Quarkus acquisition timeout is 200ms. `TestSessionConnectorSetsStatementTimeout` and `TestOpenGormWithStatementTimeoutSetsMaxExecutionTime` passed. Go RAG now uses the same session cap. The process on http://127.0.0.1:18080 is artifacts/go-backend-lock7.exe, pid 48352. /actuator/health returned 200. After that restart, performance_schema showed traffic 70 connections at max_execution_time 3000 and rag_db 1 connection at 3000. None of those sessions were 0. Targets were not loosened.

## After: Go lock7, 2026-09-28, 5 minutes
scripts/k6/full-api-load.js against artifacts/go-backend-lock7.exe, pid 48352, at http://127.0.0.1:18080. This is the process after RAG MySQL sessions were capped at 3 seconds. Profile: 5 minutes, user 8, admin 6, super 2, login 1/s, include_ai=false. Summary artifacts/k6/full-api-go-lock7-5m.log and artifacts/k6/full-api-go-lock7-5m.json. Stderr was empty. 0 interrupted iterations.
requests=61772. http_req_failed_rate=0. checks_rate=1. p95=4.206ms. p99=7.612ms.
health_ok_rate=1. login_ok_rate=1. user_read_ok_rate=1. admin_read_ok_rate=1. super_read_ok_rate=1.
payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. fine_record stayed 4. appeal_record stayed 1. appeal_review stayed 0. deduction_record stayed 0. Targets were not loosened.

## Go and Quarkus ledger read with Ollama down, 2026-09-28
Windows Ollama and Ubuntu ollama.service were stopped together. 127.0.0.1:11434 refused connections. scripts/k6/ledger-read.js ran for 5 minutes at 16 VUs on both processes at the same time. During that run, Go POST /api/ai/chat/stream returned 200 in 758ms with isFallback true, and Quarkus GET /api/ai/chat returned 200 in 6ms with isFallback true and reason model_unavailable. Ollama was started again afterward. GET http://127.0.0.1:11434/api/tags returned 200. Targets were not loosened.

Go http://127.0.0.1:18080, artifacts/go-backend-lock7.exe. Summary artifacts/k6/go-ollama-down-ledger-5m.log. Stderr only warned that the second k6 process could not bind 127.0.0.1:6565. requests=90313, including the setup login. checks=90312/90312. http_req_failed=0/90313. p95=5.24ms. p99=12.27ms. 0 interrupted iterations.

Quarkus http://127.0.0.1:19080. Summary artifacts/k6/quarkus-ollama-down-ledger-5m.log. Stderr was empty. requests=59210, including the setup login. checks=59209/59209. http_req_failed=0/59210. p95=162.7ms. p99=206.38ms. 0 interrupted iterations.

payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00.

## Cloud ledger read with Ollama down, 2026-09-28
Windows Ollama and Ubuntu ollama.service were stopped. 127.0.0.1:11434 refused connections. scripts/k6/ledger-read.js ran for 5 minutes at 16 VUs through the gateway http://127.0.0.1:18090. During that run, GET /api/ai/chat/actions returned 200 in 717ms with isFallback true. Summary artifacts/k6/cloud-ollama-down-ledger-5m.log. Stderr was empty. 0 interrupted iterations.
requests=88585, including the setup login. checks=88584/88584. http_req_failed=0/88585. p95=5.87ms. p99=8.24ms.
Ollama was started again. GET http://127.0.0.1:11434/api/tags returned 200. payment_record stayed 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount stayed 202.00 and unpaid_amount stayed -3.00. Targets were not loosened.

## Go overload on lock7, 2026-09-28
scripts/k6/ledger-shed.js against artifacts/go-backend-lock7.exe at http://127.0.0.1:18080. 200 VUs for 8 seconds. Summary artifacts/k6/ledger-shed-go-lock7-200.log. Stderr was empty. Exit 0. 0 interrupted iterations.
checks=21108/21108. shed_503=15. Every 503 in those checks carried Retry-After 1. k6 http_req_failed was 15/15832 because it counts those intentional 503 responses. Replay did not create another payment for the same key.
The run inserted 5277 shed payments. They and the shed-% history keys were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. fine_record is 4. appeal_record is 1. appeal_review is 0. deduction_record is 0. Targets were not loosened.

## Kafka down on lock7 and the current processes, 2026-09-28
final-assignment-redpanda was stopped. Each current process created one payment. All four returned 201 before the producer gave up: Go 13ms, Spring 76ms, Cloud through http://127.0.0.1:18090 52ms, and Quarkus 24ms. kafka_publish_failed_total then moved from 0 to 1 on Go, 1 to 2 on Spring, 1 to 2 on Cloud traffic, and 1 to 2 on Quarkus. Each history row was SUCCESS and its business_id was the inserted payment_id. The probe payments and probe-kafka history rows were deleted. payment_record is 13 rows, max payment_id 13, sum 809.00. fine 1 paid_amount is 202.00 and unpaid_amount is -3.00. Redpanda was started again and is healthy. Elasticsearch stayed healthy. Targets were not loosened.
