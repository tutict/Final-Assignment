package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class CloudHealthDetailsTest {

    @Test
    void publicHealthDoesNotShowDetails() throws Exception {
        Path root = Path.of("..");
        for (String relative : new String[] {
                "config/local-dev.yml",
                "finalassignmentcloud-auth/src/main/resources/application.yml",
                "finalassignmentcloud-user/src/main/resources/application.yml",
                "finalassignmentcloud-traffic/src/main/resources/application.yml",
                "finalassignmentcloud-audit/src/main/resources/application.yml",
                "finalassignmentcloud-system/src/main/resources/application.yml",
                "finalassignmentcloud-ai/src/main/resources/application.yml",
                "finalassignmentcloud-search/src/main/resources/application.yml",
                "finalassignmentcloud-rag/src/main/resources/application.yml",
                "finalassignmentcloud-gateway/src/main/resources/application.yml"
        }) {
            assertTrue(Files.readString(root.resolve(relative)).contains("show-details: never"), relative);
        }
    }
}
