package com.tutict.finalassignmentcloud.gateway;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class GatewayRouteContractTest {

    @Test
    void devRoutesKeepBusinessTimeoutsAndDoNotRetry() throws Exception {
        String main = Files.readString(Path.of("src/main/resources/application.yml"));
        String dev = Files.readString(Path.of("src/main/resources/application-dev.yml"));
        assertTrue(main.contains("response-timeout: 3s"));
        assertTrue(dev.contains("response-timeout: 3s"));
        assertTrue(section(dev, "id: rag-service", "id: search-service").contains("response-timeout: 8000"));
        assertTrue(section(dev, "id: ai-service", "server:").contains("response-timeout: 8000"));
        assertFalse(main.contains("name: Retry") || main.contains("retries:"), main);
        assertFalse(dev.contains("name: Retry") || dev.contains("retries:"), dev);
        assertTrue(main.contains("redis:") && main.contains("enabled: ${MANAGEMENT_HEALTH_REDIS_ENABLED:false}"), main);
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
            assertTrue(main.contains(origin), origin);
            assertTrue(dev.contains(origin), origin);
        }
    }

    private static String section(String text, String start, String end) {
        int from = text.indexOf(start);
        int to = text.indexOf(end, from + start.length());
        assertTrue(from >= 0 && to > from, start);
        return text.substring(from, to);
    }
}
