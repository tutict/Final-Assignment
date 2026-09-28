package com.tutict.finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class HealthDetailsConfigTest {

    @Test
    void publicHealthDoesNotShowDetails() throws Exception {
        String text = Files.readString(Path.of("src/main/resources/application.yml"));
        assertTrue(text.contains("show-details: never"));
        assertTrue(!text.contains("show-details: when-authorized"));
    }
}
