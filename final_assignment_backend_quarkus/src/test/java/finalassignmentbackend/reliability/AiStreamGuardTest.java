package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.smallrye.mutiny.Multi;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

class AiStreamGuardTest {

    @Test
    void silentModelFallsBackWithinTheBound() {
        AtomicInteger fallbacks = new AtomicInteger();
        String item = AiStreamGuard.bound(Multi.createFrom().nothing(), Duration.ofMillis(30), fallbacks::incrementAndGet)
                .collect().first()
                .await().atMost(Duration.ofSeconds(2));
        assertTrue(item.contains("\"isFallback\":true"));
        assertEquals(1, fallbacks.get());
    }

    @Test
    void firstTokenPassesThrough() {
        String item = AiStreamGuard.bound(Multi.createFrom().item("ok"), Duration.ofSeconds(1), () -> {
            throw new IllegalStateException("should not fall back");
        }).collect().first().await().atMost(Duration.ofSeconds(1));
        assertEquals("ok", item);
    }
}
