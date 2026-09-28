package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class CloudSqlTimeoutConfigTest {

    @Test
    void cloudMysqlServicesSetStatementTimeout() throws Exception {
        Path root = Path.of("..");
        assertTrue(Files.readString(root.resolve("config/local-dev.yml")).contains("max_execution_time=3000"));
        for (String relative : new String[] {
                "finalassignmentcloud-auth/src/main/resources/application.yml",
                "finalassignmentcloud-auth/src/main/resources/application-dev.yml",
                "finalassignmentcloud-auth/src/test/resources/application-test.yml",
                "finalassignmentcloud-user/src/main/resources/application-dev.yml",
                "finalassignmentcloud-audit/src/main/resources/application-dev.yml",
                "finalassignmentcloud-system/src/main/resources/application-dev.yml",
                "finalassignmentcloud-rag/src/main/resources/application.yml",
                "finalassignmentcloud-rag/src/main/resources/application-dev.yml",
                "finalassignmentcloud-traffic/src/main/resources/application-dev.yml",
                "finalassignmentcloud-traffic/src/main/resources/application.yml"
        }) {
            String text = Files.readString(root.resolve(relative));
            assertTrue(text.contains("max_execution_time=3000"), relative);
        }
    }
}
