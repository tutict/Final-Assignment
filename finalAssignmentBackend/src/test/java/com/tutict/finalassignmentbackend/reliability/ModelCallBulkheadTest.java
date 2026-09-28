package com.tutict.finalassignmentbackend.reliability;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class ModelCallBulkheadTest {

    @Test
    void thirdCallIsRejectedWithoutWaiting() {
        ModelCallBulkhead gate = new ModelCallBulkhead();

        assertThat(gate.tryAcquire()).isTrue();
        assertThat(gate.tryAcquire()).isTrue();
        assertThat(gate.tryAcquire()).isFalse();

        gate.release();
        assertThat(gate.tryAcquire()).isTrue();
    }
}
