package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class OffenseDeadLetterConfigTest {

    @Test
    void offenseConsumersUseExistingDeadLetterTopics() throws Exception {
        String text = Files.readString(Path.of("src/main/resources/application.yaml"));
        assertTrue(text.contains("      offense_create:"));
        assertTrue(text.contains("topic: offense_create.DLT"));
        assertTrue(text.contains("      offense_update:"));
        assertTrue(text.contains("topic: offense_update.DLT"));
    }
}
