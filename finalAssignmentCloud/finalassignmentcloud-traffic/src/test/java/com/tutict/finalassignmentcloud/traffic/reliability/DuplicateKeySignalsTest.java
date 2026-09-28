package com.tutict.finalassignmentcloud.traffic.reliability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class DuplicateKeySignalsTest {

    @Test
    void detectsADuplicateEntryAndIgnoresOtherFailures() {
        assertTrue(DuplicateKeySignals.duplicateKey(new IllegalStateException("Duplicate entry 'k' for key 'uk'")));
        assertTrue(DuplicateKeySignals.duplicateKey(new RuntimeException(new IllegalStateException("Duplicate entry 'k'"))));
        assertFalse(DuplicateKeySignals.duplicateKey(new IllegalStateException("validation")));
    }
}