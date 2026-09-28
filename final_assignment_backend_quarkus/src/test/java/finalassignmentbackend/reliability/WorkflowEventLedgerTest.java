package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import finalassignmentbackend.entity.SysRequestHistory;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

class WorkflowEventLedgerTest {

    @Test
    void sameEventReplaysAndDifferentEventConflicts() {
        MemoryStore store = new MemoryStore();
        WorkflowEventLedger ledger = new WorkflowEventLedger(store);
        ledger.reserve("pay-1", "PAYMENT_STATUS", "/api/workflow/payments/4/events/PAY", 4, "PAY");
        ledger.markSuccess("pay-1", 4);

        assertThrows(IdempotencyReplayException.class,
                () -> ledger.reserve("pay-1", "PAYMENT_STATUS", "/api/workflow/payments/4/events/PAY", 4, "pay"));
        assertThrows(IdempotencyConflictException.class,
                () -> ledger.reserve("pay-1", "PAYMENT_STATUS", "/api/workflow/payments/4/events/CANCEL", 4, "CANCEL"));
        assertEquals("SUCCESS", store.rows.get("pay-1").getBusinessStatus());
    }

    @Test
    void inProgressConflictsUntilFailureCanBeRetried() {
        MemoryStore store = new MemoryStore();
        WorkflowEventLedger ledger = new WorkflowEventLedger(store);
        ledger.reserve("appeal-1", "APPEAL_STATUS", "/api/workflow/appeals/8/events/START", 8, "START");
        assertThrows(IdempotencyInProgressException.class,
                () -> ledger.reserve("appeal-1", "APPEAL_STATUS", "/api/workflow/appeals/8/events/START", 8, "START"));

        String first = store.rows.get("appeal-1").getRequestParams();
        ledger.markFailed("appeal-1", "workflow transition rejected");
        assertEquals("FAILED", store.rows.get("appeal-1").getBusinessStatus());
        assertEquals("workflow transition rejected", store.rows.get("appeal-1").getRequestParams());

        ledger.reserve("appeal-1", "APPEAL_STATUS", "/api/workflow/appeals/8/events/APPROVE", 8, "APPROVE");
        assertEquals("PROCESSING", store.rows.get("appeal-1").getBusinessStatus());
        assertTrue(store.rows.get("appeal-1").getRequestParams().startsWith("sha256:"));
        assertNotEquals(first, store.rows.get("appeal-1").getRequestParams());
    }

    @Test
    void blankKeyIsRejectedAndDuplicateInsertUsesTheExistingRow() {
        MemoryStore store = new MemoryStore();
        WorkflowEventLedger ledger = new WorkflowEventLedger(store);
        assertThrows(IllegalArgumentException.class,
                () -> ledger.reserve("  ", "PAYMENT_STATUS", "/api/workflow/payments/1/events/PAY", 1, "PAY"));

        WorkflowEventLedger.Store race = new WorkflowEventLedger.Store() {
            private SysRequestHistory saved;

            @Override
            public SysRequestHistory find(String key) {
                return saved;
            }

            @Override
            public void insert(SysRequestHistory row) {
                saved = new SysRequestHistory();
                saved.setIdempotencyKey(row.getIdempotencyKey());
                saved.setRequestParams(row.getRequestParams());
                saved.setBusinessStatus("SUCCESS");
                saved.setUpdatedAt(LocalDateTime.now());
                throw new RuntimeException("duplicate");
            }

            @Override
            public void update(SysRequestHistory row) {
                saved = row;
            }
        };
        assertThrows(IdempotencyReplayException.class,
                () -> new WorkflowEventLedger(race).reserve("race", "PAYMENT_STATUS", "/api/workflow/payments/1/events/PAY", 1, "PAY"));
    }


    @Test
    void concurrentReserveHasOneWinner() throws Exception {
        java.util.concurrent.atomic.AtomicReference<SysRequestHistory> saved = new java.util.concurrent.atomic.AtomicReference<>();
        java.util.concurrent.atomic.AtomicInteger inserts = new java.util.concurrent.atomic.AtomicInteger();
        WorkflowEventLedger.Store store = new WorkflowEventLedger.Store() {
            @Override
            public synchronized SysRequestHistory find(String key) {
                return saved.get();
            }

            @Override
            public synchronized void insert(SysRequestHistory row) {
                if (!inserts.compareAndSet(0, 1)) {
                    throw new RuntimeException("duplicate");
                }
                saved.set(row);
            }

            @Override
            public synchronized void update(SysRequestHistory row) {
                saved.set(row);
            }
        };
        WorkflowEventLedger ledger = new WorkflowEventLedger(store);
        java.util.concurrent.ExecutorService pool = java.util.concurrent.Executors.newFixedThreadPool(8);
        java.util.List<java.util.concurrent.Future<Throwable>> futures = new java.util.ArrayList<>();
        for (int i = 0; i < 8; i++) {
            futures.add(pool.submit(() -> {
                try {
                    ledger.reserve("same", "PAYMENT_STATUS", "/api/workflow/payments/1/events/PAY", 1, "PAY");
                    return null;
                } catch (RuntimeException ex) {
                    return ex;
                }
            }));
        }
        pool.shutdown();
        assertTrue(pool.awaitTermination(5, java.util.concurrent.TimeUnit.SECONDS));
        int winners = 0;
        int absorbed = 0;
        for (java.util.concurrent.Future<Throwable> future : futures) {
            Throwable error = future.get();
            if (error == null) {
                winners++;
            } else if (error instanceof IdempotencyReplayException || error instanceof IdempotencyInProgressException) {
                absorbed++;
            } else {
                throw new RuntimeException(error);
            }
        }
        assertEquals(1, winners);
        assertEquals(7, absorbed);
        assertEquals(1, inserts.get());
    }

    private static final class MemoryStore implements WorkflowEventLedger.Store {
        private final Map<String, SysRequestHistory> rows = new HashMap<>();

        @Override
        public SysRequestHistory find(String key) {
            return rows.get(key);
        }

        @Override
        public void insert(SysRequestHistory row) {
            if (rows.containsKey(row.getIdempotencyKey())) {
                throw new RuntimeException("duplicate");
            }
            rows.put(row.getIdempotencyKey(), row);
        }

        @Override
        public void update(SysRequestHistory row) {
            rows.put(row.getIdempotencyKey(), row);
        }
    }
}
