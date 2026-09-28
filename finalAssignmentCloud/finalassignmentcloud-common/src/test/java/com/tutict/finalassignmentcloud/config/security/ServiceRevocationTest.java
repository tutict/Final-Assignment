package com.tutict.finalassignmentcloud.config.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.HashMap;
import org.junit.jupiter.api.Test;

class ServiceRevocationTest {

    @Test
    void redisHitIsRevokedAndOutageShedsWritesOnly() {
        HashMap<String, Long> local = new HashMap<>();
        assertEquals(ServiceRevocation.Verdict.REVOKED, ServiceRevocation.inspect(local, "token-a", true));
        assertEquals(ServiceRevocation.Verdict.REVOKED, ServiceRevocation.inspect(local, "token-a", null));
        assertTrue(ServiceRevocation.denied(ServiceRevocation.Verdict.REVOKED));
        assertTrue(ServiceRevocation.shed("POST", "/api/payments", ServiceRevocation.Verdict.UNAVAILABLE));
        assertFalse(ServiceRevocation.shed("GET", "/api/payments", ServiceRevocation.Verdict.UNAVAILABLE));
        assertEquals(ServiceRevocation.Verdict.CLEAR, ServiceRevocation.inspect(new HashMap<>(), "token-b", false));
    }
}
