package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class ModelCallBulkheadTest {

    @Test
    void thirdCallIsRejectedWithoutWaiting() {
        ModelCallBulkhead gate = new ModelCallBulkhead();

        assertTrue(gate.tryAcquire());
        assertTrue(gate.tryAcquire());
        assertFalse(gate.tryAcquire());

        gate.release();
        assertTrue(gate.tryAcquire());
    }
}
