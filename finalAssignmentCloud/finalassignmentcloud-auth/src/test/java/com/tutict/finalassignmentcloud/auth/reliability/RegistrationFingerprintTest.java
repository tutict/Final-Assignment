package com.tutict.finalassignmentcloud.auth.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.tutict.finalassignmentcloud.reliability.LedgerFingerprint;
import org.junit.jupiter.api.Test;

class RegistrationFingerprintTest {

    private static final String SECRET = "unit-test-internal-service-token-32bytes-ok";

    private RegistrationFingerprint fingerprint() {
        return new RegistrationFingerprint("", SECRET);
    }

    @Test
    void sameRequestProducesSameFingerprint() {
        RegistrationFingerprint fingerprint = fingerprint();

        assertEquals(fingerprint.fingerprint("alice", "s3cret"), fingerprint.fingerprint("alice", "s3cret"));
    }

    @Test
    void differentPasswordProducesDifferentFingerprint() {
        RegistrationFingerprint fingerprint = fingerprint();

        assertNotEquals(fingerprint.fingerprint("alice", "s3cret"), fingerprint.fingerprint("alice", "other"));
    }

    @Test
    void differentUsernameProducesDifferentFingerprint() {
        RegistrationFingerprint fingerprint = fingerprint();

        assertNotEquals(fingerprint.fingerprint("alice", "s3cret"), fingerprint.fingerprint("bob", "s3cret"));
    }

    @Test
    void fingerprintIsRecognizedByTheSharedLedgerFormat() {
        String value = fingerprint().fingerprint("alice", "s3cret");

        assertTrue(LedgerFingerprint.isFingerprint(value));
    }

    @Test
    void fingerprintDoesNotLeakThePassword() {
        String value = fingerprint().fingerprint("alice", "s3cret");

        assertFalse(value.contains("s3cret"));
    }

    @Test
    void differentSecretProducesDifferentFingerprint() {
        String value = fingerprint().fingerprint("alice", "s3cret");
        String other = new RegistrationFingerprint("", "another-internal-service-token-32bytes").fingerprint("alice", "s3cret");

        assertNotEquals(value, other);
    }

    @Test
    void missingSecretFailsFast() {
        assertThrows(IllegalStateException.class, () -> new RegistrationFingerprint("", "  "));
    }
}
