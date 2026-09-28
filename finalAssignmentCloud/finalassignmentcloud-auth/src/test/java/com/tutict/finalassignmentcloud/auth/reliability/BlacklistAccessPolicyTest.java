package com.tutict.finalassignmentcloud.auth.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class BlacklistAccessPolicyTest {

    @Test
    void revokedIsDeniedAndUnknownOutageShedsWritesOnly() {
        assertEquals(BlacklistAccessPolicy.Effect.DENY, BlacklistAccessPolicy.decide(
                "GET", "/api/payments", BlacklistAccessPolicy.Verdict.REVOKED));
        assertEquals(BlacklistAccessPolicy.Effect.SHED, BlacklistAccessPolicy.decide(
                "POST", "/api/payments", BlacklistAccessPolicy.Verdict.UNAVAILABLE));
        assertEquals(BlacklistAccessPolicy.Effect.SHED, BlacklistAccessPolicy.decide(
                "POST", "/api/auth/login", BlacklistAccessPolicy.Verdict.UNAVAILABLE));
        assertEquals(BlacklistAccessPolicy.Effect.ALLOW, BlacklistAccessPolicy.decide(
                "GET", "/api/payments", BlacklistAccessPolicy.Verdict.UNAVAILABLE));
        assertEquals(BlacklistAccessPolicy.Effect.ALLOW, BlacklistAccessPolicy.decide(
                "POST", "/api/payments", BlacklistAccessPolicy.Verdict.CLEAR));
    }
}
