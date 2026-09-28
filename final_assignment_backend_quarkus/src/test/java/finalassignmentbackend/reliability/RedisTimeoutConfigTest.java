package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class RedisTimeoutConfigTest {

    @Test
    void blacklistRedisCommandTimeoutIs200ms() throws Exception {
        String text = Files.readString(Path.of("src/main/resources/application.yaml"));
        assertTrue(text.contains("timeout: 300ms"));
        assertTrue(text.contains("blacklist:"));
        assertTrue(text.contains("timeout: 200ms"));
    }
}
