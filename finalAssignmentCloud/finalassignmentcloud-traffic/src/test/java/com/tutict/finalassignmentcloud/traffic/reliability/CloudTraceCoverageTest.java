package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class CloudTraceCoverageTest {

    @Test
    void servicesScanTheTraceFilterAndLogsIncludeTheId() throws Exception {
        Path root = Path.of("..");
        for (String app : new String[] {
                "finalassignmentcloud-auth/src/main/java/com/tutict/finalassignmentcloud/auth/FinalAssignmentCloudAuthApplication.java",
                "finalassignmentcloud-audit/src/main/java/com/tutict/finalassignmentcloud/audit/FinalAssignmentCloudAuditApplication.java",
                "finalassignmentcloud-search/src/main/java/com/tutict/finalassignmentcloud/search/FinalAssignmentCloudSearchApplication.java",
                "finalassignmentcloud-ai/src/main/java/com/tutict/finalassignmentcloud/ai/FinalAssignmentCloudAiApplication.java"
        }) {
            assertTrue(Files.readString(root.resolve(app)).contains("com.tutict.finalassignmentcloud.observability"), app);
        }
        for (String config : new String[] {
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
            String text = Files.readString(root.resolve(config));
            assertTrue(text.contains("traceId=%X{traceId:-}"), config);
        }
    }
}
