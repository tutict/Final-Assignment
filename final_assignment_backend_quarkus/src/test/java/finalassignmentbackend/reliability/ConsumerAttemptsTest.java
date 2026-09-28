package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

class ConsumerAttemptsTest {

    @Test
    void retriesThreeTimesThenThrows() {
        AtomicInteger calls = new AtomicInteger();
        RuntimeException thrown = assertThrows(RuntimeException.class, () -> ConsumerAttempts.run(() -> {
            calls.incrementAndGet();
            throw new IllegalStateException("down");
        }, delay -> { }));
        assertEquals(4, calls.get());
        assertEquals("down", thrown.getMessage());
    }

    @Test
    void stopsWhenTheCallSucceeds() {
        AtomicInteger calls = new AtomicInteger();
        ConsumerAttempts.run(() -> {
            if (calls.incrementAndGet() < 3) {
                throw new IllegalStateException("transient");
            }
        }, delay -> { });
        assertEquals(3, calls.get());
    }

    @Test
    void doesNotRetryPoisonMessages() {
        AtomicInteger calls = new AtomicInteger();
        assertThrows(IllegalArgumentException.class, () -> ConsumerAttempts.run(() -> {
            calls.incrementAndGet();
            throw new IllegalArgumentException("bad");
        }, delay -> { }));
        assertEquals(1, calls.get());
    }
    @Test
    void checkedFailureRetriesThenThrows() {
        AtomicInteger calls = new AtomicInteger();
        RuntimeException thrown = assertThrows(RuntimeException.class, () -> ConsumerAttempts.runChecked(() -> {
            calls.incrementAndGet();
            throw new Exception("checked");
        }));
        assertEquals(4, calls.get());
        assertEquals("checked", thrown.getCause().getMessage());
    }
}
