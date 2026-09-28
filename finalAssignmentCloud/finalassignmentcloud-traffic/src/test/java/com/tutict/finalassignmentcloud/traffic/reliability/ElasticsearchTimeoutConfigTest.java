package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class ElasticsearchTimeoutConfigTest {

    @Test
    void searchCallsAreBoundedTo800ms() throws Exception {
        String text = Files.readString(Path.of("src/main/resources/application-dev.yml"));
        assertTrue(text.contains("connection-timeout: ${ELASTICSEARCH_CONNECT_TIMEOUT:800ms}"));
        assertTrue(text.contains("socket-timeout: ${ELASTICSEARCH_SOCKET_TIMEOUT:800ms}"));
    }
}
