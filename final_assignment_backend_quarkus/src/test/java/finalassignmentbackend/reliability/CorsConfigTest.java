package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class CorsConfigTest {

    @Test
    void browserOriginsMatchSpring() throws Exception {
        String text = Files.readString(Path.of("src/main/resources/application.yaml"));
        assertTrue(text.contains("cors:"));
        assertFalse(text.contains("origins: *"));
        assertFalse(text.contains("\\d+"));
        for (String origin : new String[] {
                "http://localhost:3000",
                "http://127.0.0.1:3000",
                "http://localhost:8080",
                "http://127.0.0.1:8080",
                "http://localhost:5173",
                "http://127.0.0.1:5173",
                "http://localhost:15173",
                "http://127.0.0.1:15173",
                "http://localhost:13000",
                "http://127.0.0.1:13000"
        }) {
            assertTrue(text.contains(origin), origin);
        }
        assertTrue(text.contains("Idempotency-Key"));
        assertTrue(text.contains("access-control-allow-credentials: true"));
    }
}
