package com.tutict.finalassignmentcloud.reliability;

import java.net.ConnectException;
import java.net.SocketTimeoutException;
import org.junit.jupiter.api.Test;
import org.springframework.data.elasticsearch.UncategorizedElasticsearchException;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ElasticsearchUnavailableGuardTest {

    @Test
    void timeoutAndClientFailuresFallBack() {
        assertTrue(ElasticsearchUnavailableGuard.unavailable(new SocketTimeoutException("Read timed out")));
        assertTrue(ElasticsearchUnavailableGuard.unavailable(new ConnectException("Connection refused")));
        assertTrue(ElasticsearchUnavailableGuard.unavailable(
                new UncategorizedElasticsearchException("search failed", new SocketTimeoutException("Read timed out"))));
        assertTrue(ElasticsearchUnavailableGuard.unavailable(
                new IllegalStateException("wrapped", new ConnectException("localhost:9200"))));
    }

    @Test
    void ordinaryFailuresStillPropagate() {
        assertFalse(ElasticsearchUnavailableGuard.unavailable(new IllegalArgumentException("bad page")));
        assertFalse(ElasticsearchUnavailableGuard.unavailable(null));
    }
}