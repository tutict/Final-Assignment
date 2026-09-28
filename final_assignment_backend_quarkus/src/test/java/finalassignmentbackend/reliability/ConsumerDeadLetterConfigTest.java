package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

class ConsumerDeadLetterConfigTest {

    @Test
    void everyIncomingChannelKeepsItsNameAndHasADeadLetterTopic() throws Exception {
        String properties = Files.readString(Path.of("src/main/resources/application.yaml"));
        StringBuilder sources = new StringBuilder();
        try (Stream<Path> files = Files.walk(Path.of("src/main/java/finalassignmentbackend/kafkaListener"))) {
            files.filter(path -> path.toString().endsWith(".java")).forEach(path -> {
                try {
                    sources.append(Files.readString(path));
                } catch (Exception ex) {
                    throw new IllegalStateException(ex);
                }
            });
        }
        Matcher matcher = Pattern.compile("@Incoming\\(\"([^\"]+)\"\\)").matcher(sources);
        int channels = 0;
        while (matcher.find()) {
            channels++;
            String channel = matcher.group(1);
            assertTrue(properties.contains("      " + channel + ":"), channel);
            assertTrue(properties.contains("topic: " + channel + ".DLT"), channel);
        }
        assertTrue(channels >= 28, "channels=" + channels);
    }
}
