package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class SqlStatementTimeoutConfigTest {

    @Test
    void newConnectionsCapExecutionAtThreeSeconds() throws Exception {
        String text = Files.readString(Path.of("src/main/resources/application.yaml"));
        assertTrue(text.contains("new-connection-sql: SET SESSION max_execution_time=3000"));
        assertTrue(text.contains("acquisition-timeout: 200ms"));
    }
}
