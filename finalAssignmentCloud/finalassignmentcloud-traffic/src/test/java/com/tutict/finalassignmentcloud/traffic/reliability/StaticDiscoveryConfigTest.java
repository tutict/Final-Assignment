package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class StaticDiscoveryConfigTest {

    @Test
    void devProfileResolvesUserServiceWithoutNacos() throws Exception {
        String[] profiles = {
                "src/main/resources/application-dev.yml",
                "../finalassignmentcloud-auth/src/main/resources/application-dev.yml",
                "../finalassignmentcloud-user/src/main/resources/application-dev.yml",
                "../finalassignmentcloud-audit/src/main/resources/application-dev.yml",
                "../finalassignmentcloud-system/src/main/resources/application-dev.yml",
                "../finalassignmentcloud-search/src/main/resources/application-dev.yml",
                "../finalassignmentcloud-rag/src/main/resources/application-dev.yml",
                "../finalassignmentcloud-ai/src/main/resources/application-dev.yml"
        };
        for (String relative : profiles) {
            String dev = Files.readString(Path.of(relative));
            assertTrue(dev.contains("finalassignmentcloud-user:"), relative);
            assertTrue(dev.contains("http://127.0.0.1:${CLOUD_USER_PORT:18082}"), relative);
            assertTrue(dev.contains("enabled: ${CLOUD_NACOS_DISCOVERY:false}"), relative);
        }
    }
}